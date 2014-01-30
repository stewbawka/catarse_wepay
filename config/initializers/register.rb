begin
  PaymentEngines.register({
    name: 'wepay',
    review_path: ->(contribution) {
      CatarseWepay::Engine.routes.url_helpers.review_wepay_path(contribution)
    },
    refund_path: ->(contribution) {
      CatarseWepay::Engine.routes.url_helpers.refund_wepay_path(contribution)
    },
    locale: 'en'
  })
rescue Exception => e
  puts "Error while registering payment engine: #{e}"
end
