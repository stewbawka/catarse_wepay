module CatarseWepay
  class Configuration
    attr_accessor :wepay_client_id, :wepay_client_secret

    def initialize
      self.wepay_client_id = ''
      self.wepay_client_secret = ''
    end
  end
end
