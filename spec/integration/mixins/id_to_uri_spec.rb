# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/mixins/md_id_to_uri'

describe GoodData::Mixin::MdIdToUri do
  before :each do
    @client = ConnectionHelper.create_default_connection
    project = ProjectHelper.get_default_project(client: @client)

    class SomeTestClass
      extend GoodData::Mixin::MdIdToUri
    end

    @opts = { client: @client, project: project }
  end

  after(:each) do
    @client.disconnect
  end

  it 'should throw BadRequest for -1' do
    expect do
      SomeTestClass.identifier_to_uri(@opts, -1)
    end.to raise_error(RestClient::BadRequest)
  end

  it 'should return nil for unknown id' do
    expect(SomeTestClass.identifier_to_uri(@opts, 0)).to be_nil
  end

  it 'should get json containing correct id' do
    facts = GoodData::Fact.all(@opts)
    fact  = facts.to_a.first
    uri = SomeTestClass.identifier_to_uri(@opts, fact.identifier)
    res = @client.get(uri)
    expect(res['fact']['meta']['identifier']).to eq fact.identifier
  end
end
