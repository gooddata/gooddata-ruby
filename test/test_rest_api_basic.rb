require 'helper'
require 'gooddata/command'

include GoodData

class TestRestApiBasic < Test::Unit::TestCase
  context "GoodData REST Client" do
    # Initialize a GoodData connection using the credential
    # stored in ~/.gooddata
    setup do
      GoodData::Command::Base.new([]).connect
    end

    should "get the FoodMartDemo" do
      p_by_hash   = Project['FoodMartDemo']
      p_by_uri    = Project['/gdc/projects/FoodMartDemo']
      p_by_md_uri = Project['/gdc/md/FoodMartDemo']
      assert_not_nil p_by_hash
      assert_equal p_by_hash.uri, p_by_uri.uri
      assert_equal p_by_hash.title, p_by_uri.title
      assert_equal p_by_hash.title, p_by_md_uri.title
    end

    should "connect to the FoodMartDemo" do
      GoodData.use 'FoodMartDemo'
      Dataset.all # should not fail on unknown project or access denied
    end

    # Not supported yet
    # should "fetch dataset by numerical or string identifier" do
    #   GoodData.use 'FoodMartDemo'
    #   ds_by_hash = Dataset['amJoIYHjgESv']
    #   ds_by_id   = Dataset[34]
    #   assert_not_nil ds_by_hash
    #   assert_equal ds_by_hash.uri, ds_by_id.uri
    # end
  end
end