require 'helper'
require 'gooddata/models/dataset'

class TestModel < Test::Unit::TestCase
  should "generate identifiers starting with letters and without ugly characters" do
    assert_equal 'fact.blah', GoodData::Fact.new({ 'name' => 'blah' }, 'ds').identifier
    assert_equal 'attr.blah', GoodData::Attribute.new({ 'name' => '1_2_3 blah' }, 'ds').identifier
    assert_equal 'dim.blaz', GoodData::AttributeFolder.new(' b*ĺ*á#ž$').identifier
  end
end
