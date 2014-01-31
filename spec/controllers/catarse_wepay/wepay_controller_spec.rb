# encoding: utf-8
require 'spec_helper'

describe CatarseWepay::WepayController do
  SCOPE = CatarseWepay::WepayController::SCOPE
  before do
    PaymentEngines.configuration.stub(:[]).with(:wepay_client_id).and_return('client-id')
    PaymentEngines.configuration.stub(:[]).with(:wepay_client_secret).and_return('client-secret')
    PaymentEngines.configuration.stub(:[]).with(:wepay_access_token).and_return('access-token')
    PaymentEngines.configuration.stub(:[]).with(:wepay_account_id).and_return('account-id')
    PaymentEngines.stub(:find_payment).and_return(contribution)
    PaymentEngines.stub(:create_payment_notification)
    controller.stub(:main_app).and_return(main_app)
    controller.stub(:current_user).and_return(current_user)
    controller.stub(:gateway).and_return(gateway)
  end
  subject{ response }
  let(:gateway){ double('gateway') }
  let(:main_app){ double('main_app') }
  let(:current_user) { double('current_user') }
  let(:project){ double('project', id: 1, name: 'test project') }
  let(:contribution){ double('contribution', {
    id: 1,
    key: 'contribution key',
    payment_id: 'payment id',
    project: project,
    pending?: true,
    value: 10,
    display_value: 'R$ 10,00',
    price_in_cents: 1000,
    user: current_user,
    payer_name: 'foo',
    payer_email: 'foo@bar.com',
    payment_token: 'token',
    address_street: 'test',
    address_number: '123',
    address_complement: '123',
    address_neighbourhood: '123',
    address_city: '123',
    address_state: '123',
    address_zip_code: '123',
    address_phone_number: '123',
    payment_method: 'WePay',
    payment_token: '508637826'
  }) }
  let(:checkout_hash) { {"checkout_id"=>508637826,
    "account_id"=>21212121,
    "type"=>"DONATION",
    "checkout_uri"=>"https://stage.wepay.com/api/checkout/508637826/4e51d293",
    "short_description"=>"Back project MyProject",
    "currency"=>"USD",
    "amount"=>120,
    "fee_payer"=>"payer",
    "state"=>"captured",
    "soft_descriptor"=>"WPY*PluribusFund",
    "redirect_uri"=>"http://localhost:3000/en/payment/wepay/3/success",
    "auto_capture"=>true,
    "app_fee"=>0,
    "create_time"=>1391132470,
    "mode"=>"regular",
    "amount_refunded"=>0,
    "amount_charged_back"=>0,
    "gross"=>123.78,
    "fee"=>3.78,
    "callback_uri"=>"http://52966c09.ngrok.com/en/payment/wepay/ipn",
    "tax"=>0,
    "payer_email"=>"payer@example.com",
    "payer_name"=>"Payer Name",
    "dispute_uri"=>
    "https://stage.wepay.com/dispute/payer_create/633461/6a17d1cff4ec53e29d29"}
  }
  describe "POST refund" do
    before do
      success_refund = double
      success_refund.stub(:success?).and_return(true)
      main_app.should_receive(:admin_contributions_path).and_return('admin_contributions_path')
      gateway.should_receive(:call).with("/checkout/refund", "access-token", {:account_id=>"account-id", :checkout_id=>"508637826", :refund_reason=>"The customer changed his mind"}).and_return({'state' => 'refunded'})
      post :refund, id: contribution.id, use_route: 'catarse_wepay'
    end
    it { should redirect_to('admin_contributions_path') }
  end
  describe "GET review" do
    before do
      get :review, id: contribution.id, use_route: 'catarse_wepay'
    end
    it{ should render_template(:review) }
  end
  describe "POST ipn" do
    context "when is a valid ipn data" do
      let(:params) { { use_route: 'catarse_wepay', checkout_id: '1477569800' } }
      before do
        gateway.should_receive(:call).with("/checkout", "access-token", {:checkout_id=>"508637826"}).and_return(checkout_hash)
        contribution.should_receive(:confirm!)
        contribution.should_receive(:update_attributes).with({
          payment_service_fee: 3.78,
          payer_email: 'payer@example.com'
        })
        post :ipn, params
      end
      its(:status){ should == 200 }
      its(:body){ should == ' ' }
    end
    context "when is not valid ipn data" do
      let(:params) { { use_route: 'catarse_wepay' } }
      before do
        contribution.should_not_receive(:update_attributes)
        post :ipn, params
      end
      its(:status){ should == 500 }
      its(:body){ should == ' ' }
    end
  end
  describe "POST pay" do
    before do
      set_wepay_response
      post :pay, { id: contribution.id, locale: 'en', use_route: 'catarse_wepay' }
    end
    context 'when fail' do
      let(:set_wepay_response) do
        gateway.should_receive(:call).with("/checkout/create", "access-token",{
          account_id: "account-id",
          amount: "10.0",
          short_description: "Back project test project",
          type: 'DONATION',
          redirect_uri: "http://test.host/catarse_wepay/payment/wepay/1/success",
          callback_uri: "http://test.host/catarse_wepay/payment/wepay/ipn"
        }).and_return(checkout_hash.merge('checkout_uri' => nil))
        main_app.should_receive(:edit_project_contribution_path).with(project_id: 1, id: 1).and_return('error url')
        contribution.should_not_receive(:update_attributes)
      end
      it 'should assign flash error' do
        controller.flash[:failure].should == I18n.t('wepay_error', scope: SCOPE)
      end
      it{ should redirect_to 'error url' }
    end
    context 'when successul' do
      let(:set_wepay_response) do
        gateway.should_receive(:call).with("/checkout/create", "access-token",{
          account_id: "account-id",
          amount: "10.0",
          short_description: "Back project test project",
          type: 'DONATION',
          redirect_uri: "http://test.host/catarse_wepay/payment/wepay/1/success",
          callback_uri: "http://test.host/catarse_wepay/payment/wepay/ipn"
        }).and_return(checkout_hash)
        contribution.should_receive(:update_attributes).with({
          payment_method: "WePay",
          payment_token: 508637826
        })
      end
      it{ should redirect_to 'https://stage.wepay.com/api/checkout/508637826/4e51d293' }
    end
  end
  describe "GET success" do
    let(:params){{ id: contribution.id, use_route: 'catarse_wepay' }}
    before do
      set_redirect_expectations
      get :success, params
    end
    context "when purchase is authorized" do
      let(:set_redirect_expectations) do
        gateway.should_receive(:call).with("/checkout", "access-token", {:checkout_id=>"508637826"}).and_return(checkout_hash.merge('state' => 'authorized'))
        main_app.
          should_receive(:project_contribution_path).
          with(project_id: contribution.project.id, id: contribution.id).
          and_return('back url')
      end
      it{ should redirect_to 'back url' }
      it 'should assign flash message' do
        controller.flash[:success].should == I18n.t('success', scope: SCOPE)
      end
    end
    context 'when wepay purchase is not authorized' do
      let(:set_redirect_expectations) do
        gateway.should_receive(:call).with("/checkout", "access-token", {:checkout_id=>"508637826"}).and_return(checkout_hash.merge('state' => 'failed'))
        main_app.
          should_receive(:new_project_contribution_path).
          with(contribution.project).
          and_return('new back url')
      end
      it 'should assign flash error' do
        controller.flash[:failure].should == I18n.t('wepay_error', scope: SCOPE)
      end
      it{ should redirect_to 'new back url' }
    end
  end
  describe "#gateway" do
    before do
      controller.stub(:gateway).and_call_original
      PaymentEngines.stub(:configuration).and_return(wepay_config)
    end
    subject{ controller.gateway }
    context "when we have the wepay configuration" do
      let(:wepay_config) do
        { wepay_client_id: 'client-id', wepay_client_secret: 'client-secret'}
      end
      before do
        WePay.should_receive(:new).with('client-id', 'client-secret').and_return('gateway instance')
      end
      it{ should == 'gateway instance' }
    end
    context "when we do not have the wepay configuration" do
      let(:wepay_config){ {} }
      before do
        WePay.should_not_receive(:new)
      end
      it { expect { subject }.to raise_exception }
    end
  end
  describe "#contribution" do
    subject{ controller.contribution }
    context "when we have an id" do
      before do
        controller.stub(:params).and_return({'id' => '1'})
        PaymentEngines.should_receive(:find_payment).with(id: '1').and_return(contribution)
      end
      it{ should == contribution }
    end
    context "when we do not have any id" do
      before do
        controller.stub(:params).and_return({})
        PaymentEngines.should_not_receive(:find_payment)
      end
      it{ should be_nil }
    end
    context "when we have an checkout_id" do
      before do
        controller.stub(:params).and_return({'checkout_id' => '1'})
        PaymentEngines.should_receive(:find_payment).with(payment_token: '1').and_return(contribution)
      end
      it{ should == contribution }
    end
  end
end
