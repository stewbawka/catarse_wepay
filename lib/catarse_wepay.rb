require 'wepay'
require "catarse_wepay/engine"
require "catarse_wepay/configuration"
require "catarse_wepay/payment_engine"

module CatarseWepay
  class << self
    attr_writer :configuration
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  def self.configure
    yield(configuration)
  end
end
