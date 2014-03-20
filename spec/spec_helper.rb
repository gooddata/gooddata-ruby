require 'rspec'
require 'coveralls'

Coveralls.wear!

# Automagically include all helpers/*_helper.rb

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + 'helpers/*_helper.rb').each do |file|
  require file
end

RSpec.configure do |config|
  include BlueprintHelper
  include CliHelper
  include ConnectionHelper
end
