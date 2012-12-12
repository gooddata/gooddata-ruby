require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gooddata'

# used in test that expect an existing accessible project
$DEMO_PROJECT = 'uhq8dikmtxog8n19jmuqn4gtj3cm2q0t'

class Test::Unit::TestCase
end
