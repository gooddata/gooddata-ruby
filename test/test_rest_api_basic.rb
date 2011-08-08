require 'logger'

require 'helper'
require 'gooddata/command'

GoodData.logger = Logger.new(STDOUT)

class TestRestApiBasic < Test::Unit::TestCase
  context "GoodData REST Client" do
    # Initialize a GoodData connection using the credential
    # stored in ~/.gooddata
    setup do
      GoodData::Command::connect
    end

    should "get the demo project" do
      p_by_hash   = GoodData::Project[$DEMO_PROJECT]
      p_by_uri    = GoodData::Project["/gdc/projects/#{$DEMO_PROJECT}"]
      p_by_md_uri = GoodData::Project["/gdc/md/#{$DEMO_PROJECT}"]
      assert_not_nil p_by_hash
      assert_equal p_by_hash.uri, p_by_uri.uri
      assert_equal p_by_hash.title, p_by_uri.title
      assert_equal p_by_hash.title, p_by_md_uri.title
    end

    should "connect to the demo project" do
      GoodData.use $DEMO_PROJECT
      GoodData.project.datasets # should not fail on unknown project or access denied
                                # TODO: should be equal to Dataset.all once implemented
    end

    # Not supported yet
    # should "fetch dataset by numerical or string identifier" do
    #   GoodData.use $DEMO_PROJECT
    #   ds_by_hash = Dataset['amJoIYHjgESv']
    #   ds_by_id   = Dataset[34]
    #   assert_not_nil ds_by_hash
    #   assert_equal ds_by_hash.uri, ds_by_id.uri
    # end
  end
end
