CatarseWepay::Engine.routes.draw do
  resources :wepay, only: [], path: 'payment/wepay' do
    collection do
      post :ipn
    end

    member do
      post :refund
      get  :review
      post :pay
      get  :success
      get  :cancel
    end
  end
end

