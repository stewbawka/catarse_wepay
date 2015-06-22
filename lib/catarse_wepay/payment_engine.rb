module CatarseWepay
  class PaymentEngine
    def name
      'wepay'
    end

    def review_path contribution
      url_helpers.review_wepay_path(contribution)
    end

    def locale
      'en'
    end

    def can_do_refund?
      false
    end

    def can_generate_second_slip?
      false
    end

    protected

    def url_helpers
      CatarseWepay::Engine.routes.url_helpers
    end
  end
end
