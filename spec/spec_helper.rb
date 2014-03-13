require 'rspec'

# Automagically include all helpers/*_helper.rb

require 'helpers/blueprint_helper'
require 'helpers/connection_helper'

RSpec.configure do |config|
  include BlueprintHelper
  include ConnectionHelper
end
