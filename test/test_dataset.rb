require 'helper'
require 'gooddata/dataset'

include Gooddata

class TestModel < Test::Unit::TestCase
  should "generate identifiers starting with letters and without ugly characters" do
    assert_equal 'blah', Dataset::Object.new({ 'name' => 'blah' }).identifier
    assert_equal 'blah', Dataset::Object.new({ 'name' => '1_2_3 blah' }).identifier
    assert_equal 'blaz', Dataset::Object.new({ 'name' => ' b*ĺ*á#ž$' }).identifier
  end
end