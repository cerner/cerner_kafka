require 'rspec/expectations'
require 'chefspec'
require 'chefspec/berkshelf'
require 'chef/node'
require_relative '../libraries/config_helper.rb'

at_exit { ChefSpec::Coverage.report! }
