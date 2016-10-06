require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/node'
require_relative '../libraries/config_helper.rb'

RSpec.configure do |config|
  config.platform = 'redhat'
  config.version = '6.6'
end

at_exit { ChefSpec::Coverage.report! }
