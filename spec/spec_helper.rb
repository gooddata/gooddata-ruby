require 'rspec'

# Automagically include all helpers/*_helper.rb
require 'helpers/blueprint_helper'

RSpec.configure do |config|
  include BlueprintHelper

  GD_PROJECT_TOKEN = ENV["GD_PROJECT_TOKEN"]
end
