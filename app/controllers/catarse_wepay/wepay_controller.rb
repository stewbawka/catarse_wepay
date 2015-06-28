class CatarseWepay::WepayController < ApplicationController
  skip_before_filter :force_http
  SCOPE = "projects.contributions.checkout"
  layout :false

  def review
  end

  def refund
    response = gateway.call('/checkout/refund', PaymentEngines.configuration[:wepay_access_token], {
        account_id: PaymentEngines.configuration[:wepay_account_id],
        checkout_id: contribution.payment_token,
        refund_reason: t('wepay_refund_reason', scope: SCOPE),
    })

    if response['state'] == 'refunded'
      flash[:notice] = I18n.t('projects.contributions.refund.success')
    else
      flash[:alert] = refund_request.try(:message) || I18n.t('projects.contributions.refund.error')
    end

    redirect_to main_app.admin_contributions_path
  end

  def ipn
    if contribution && (contribution.payment_method == 'WePay' || contribution.payment_method.nil?)
      response = gateway.call('/checkout', PaymentEngines.configuration[:wepay_access_token], {
          checkout_id: contribution.payment_token,
      })
      PaymentEngines.create_payment_notification contribution_id: contribution.id, extra_data: response
      if response["state"]
        case response["state"].downcase
        when 'captured'
          contribution.confirm!
        when 'refunded'
          contribution.refund!
        when 'cancelled'
          contribution.cancel!
        when 'expired', 'failed'
          contribution.pendent!
        when 'authorized', 'reserved'
          contribution.waiting! if contribution.pending?
        end
      end
      contribution.update_attributes({
        :payment_service_fee => response['fee'],
        :payer_email => response['payer_email']
      })
    else
      return render status: 500, nothing: true
    end
    return render status: 200, nothing: true
  rescue Exception => e
    return render status: 500, text: e.inspect
  end

  def pay
    payment.update_attributes({
      gateway: 'Wepay', payment_method: 'Wepay'})
    payment.save

    response = gateway.call('/checkout/create', PaymentEngines.configuration[:wepay_access_token], {
        account_id: PaymentEngines.configuration[:wepay_account_id],
        amount: (contribution.price_in_cents/100).round(2).to_s,
        short_description: t('wepay_description', scope: SCOPE, :project_name => contribution.project.name, :value => contribution.value),
        type: 'DONATION',
        redirect_uri: success_wepay_url(id: contribution.id),
        callback_uri: ipn_wepay_index_url(callback_uri_params)
    })
    binding.pry
    if response['checkout_uri']
      payment.update_attributes(gateway_data: {token: response['checkout_id']})
      redirect_to response['checkout_uri']
    else
      flash[:failure] = t('wepay_error', scope: SCOPE)
      return redirect_to main_app.edit_project_contribution_path(project_id: contribution.project.id, id: contribution.id)
    end
  end

  def callback_uri_params
    {host: '52966c09.ngrok.com', port: 80} if Rails.env.development?
  end

  def success
    success = false
    binding.pry
    response = nil
    if gateway_data = payment.gateway_data
      if token = gateway_data["token"]
        binding.pry
        response = gateway.call('/checkout', PaymentEngines.configuration[:wepay_access_token], {
            checkout_id: token,
        })
        if response['state'] == 'authorized'
          success = true
          binding.pry
        end
      end
    end

    change_payment_state(payment, response)

    if success
      flash[:success] = t('success', scope: SCOPE)
      redirect_to main_app.project_contribution_path(project_id: contribution.project.id, id: contribution.id)
    else
      flash[:failure] = t('wepay_error', scope: SCOPE)
      redirect_to main_app.new_project_contribution_path(contribution.project)
    end
  end

  def contribution
    @contribution ||= PaymentEngines.find_contribution(params[:id])
  end

  def payment
    attributes = {contribution: contribution, value: contribution.value}
    @payment ||= PaymentEngines.new_payment(attributes)
  end

  def gateway
    raise "[WePay] An API Client ID and Client Secret are required to make requests to WePay" unless PaymentEngines.configuration[:wepay_client_id] and PaymentEngines.configuration[:wepay_client_secret]
    @gateway ||= WePay.new(PaymentEngines.configuration[:wepay_client_id], PaymentEngines.configuration[:wepay_client_secret])
  end

  def change_payment_state(payment, response)
    binding.pry
    #there is a concern in the catarse_pagarme gem that will update the payment further with info for 
    #'acquirer data', card brand, installment value,  gateawy fee...
    #delegator.update_transaction  
    self.payment.payment_notifications.create(contribution_id: self.payment.contribution_id)
  end

  def attributes_to_payment
    {
      payment_method: 'Wepay',
      gateway_id: nil
    }
  end
end
