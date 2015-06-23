#encoding: utf-8
$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "catarse_wepay/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "catarse_wepay"
  s.version     = CatarseWepay::VERSION
  s.authors     = ["Stuart Wade"]
  s.email       = ["stewbawka@gmail.com"]
  s.homepage    = "http://github.com/stewbawka/catarse_wepay"
  s.summary     = "Wepay integration with Catarse"
  s.description = "Wepay integration with Catarse crowdfunding platform"

  s.files      = `git ls-files`.split($\)
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  s.add_dependency "rails", "~> 4.0"
  s.add_dependency "slim-rails"
  s.add_dependency "wepay", "0.0.1"

  s.add_development_dependency "rspec-rails", '~> 2.14.0'
  s.add_development_dependency "factory_girl_rails"
  s.add_development_dependency "database_cleaner"
end
