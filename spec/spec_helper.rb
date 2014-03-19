require 'rspec'
require 'coveralls'

Coveralls.wear!

# Automagically include all helpers/*_helper.rb

require File.join(File.dirname(__FILE__), 'helpers/blueprint_helper')
require File.join(File.dirname(__FILE__), 'helpers/connection_helper.rb')

RSpec.configure do |config|
  include BlueprintHelper
  include ConnectionHelper
end
