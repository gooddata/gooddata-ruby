require 'helper'
require 'gooddata/model'

class TestModel < Test::Unit::TestCase
  should "generate identifiers starting with letters and without ugly characters" do
    assert_equal 'fact.blah', GoodData::Model::Fact.new({ 'name' => 'blah' }, 'ds').identifier
    assert_equal 'attr.blah', GoodData::Model::Attribute.new({ 'name' => '1_2_3 blah' }, 'ds').identifier
    assert_equal 'dim.blaz', GoodData::Model::AttributeFolder.new(' b*ĺ*á#ž$').identifier
  end
end
