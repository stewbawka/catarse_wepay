# CatarseWePay [![Build Status](https://travis-ci.org/rafaelp/catarse_wepay.png?v=1)](https://travis-ci.org/rafaelp/catarse_wepay)

Catarse WePay express integration with [Catarse](http://github.com/catarse/catarse) crowdfunding platform

## Installation

Add this lines to your Catarse application's Gemfile:

    gem 'catarse_wepay'

And then execute:

    $ bundle

## Usage

Configure the routes for your Catarse application. Add the following lines in the routes file (config/routes.rb):

    mount CatarseWepay::Engine => "/", :as => "catarse_wepay"

### Configurations

Create this configurations into Catarse database:

    wepay_client_id, wepay_client_secret, wepay_access_token and wepay_account_id

In Rails console, run this:

    Configuration.create!(name: "wepay_client_id", value: "999999")
    Configuration.create!(name: "wepay_client_secret", value: "xxxxxxxxxx")
    Configuration.create!(name: "wepay_access_token", value: "STAGE_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx")
    Configuration.create!(name: "wepay_account_id", value: "999999999")

## Development environment setup

Clone the repository:

    $ git clone git://github.com/rafaelp/catarse_wepay.git

Add the catarse code into test/dummy:

    $ git submodule init
    $ git submodule update

And then execute:

    $ bundle

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## Credits

CatarseWePay was forked from [catarse_paypal_express](https://github.com/catarse/catarse_paypal_express) and written by [Rafael Lima](http://rafael.adm.br).

## License

CatarseWePay is Copyright © 2014 Rafael Lima. It is free software, and may be redistributed under the terms specified in the [MIT-LICENSE](https://github.com/rafaelp/catarse_wepay/blob/master/MIT-LICENSE) file.