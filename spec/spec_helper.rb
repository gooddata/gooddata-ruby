# Automagically include all helpers/*_helper.rb
require 'helpers/blueprint_helper'

RSpec.configure do |config|
  include BlueprintHelper
end
