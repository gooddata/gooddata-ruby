require 'rubygems'
require 'test/unit'
require 'shoulda'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'gooddata'

# used in test that expect an existing accessible project
$DEMO_PROJECT = 'ca6a1r1lbfwpt2v05k36nbc0cjpu7lh9'

class Test::Unit::TestCase
end
