# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/commands/datasets'

describe GoodData::Command::Datasets do
  before(:each) do
    @client = ConnectionHelper::create_default_connection
    @cmd = GoodData::Command::Datasets.new()
  end

  after(:each) do
    @client.disconnect
  end

  it "Is Possible to create GoodData::Command::Datasets instance" do
    @cmd.should be_a(GoodData::Command::Datasets)
  end

  describe "#index" do
    it "Lists all datasets" do
      skip("GoodData::Command::Dataset#with_project not working")
      @cmd.index
    end
  end

  describe "#describe" do
    it "Describes dataset" do
      skip("GoodData::Command::Dataset#extract_option not working")
      @cmd.describe
    end
  end

  describe "#apply" do
    it "Creates a server-side model" do
      skip("GoodData::Command::Dataset#with_project not working")
      @cmd.apply
    end
  end

  describe "#load" do
    it "Loads a CSV file into an existing dataset" do
      skip("GoodData::Command::Dataset#with_project not working")
      @cmd.load
    end
  end
end