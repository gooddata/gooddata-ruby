# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::Segment do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  before(:each) do
    @uuid = SecureRandom.uuid
    @master_project = @client.create_project(title: "Test MASTER project for #{@uuid}", auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
    @segment_name = "segment-#{@uuid}"
    @segment = @domain.create_segment(segment_id: @segment_name, master_project: @master_project)
  end

  after(:each) do
    @master_project.delete if @master_project
    @segment && @segment.delete(force: true)
  end

  after(:all) do
    @client.disconnect
  end

  describe '#[]' do
    it 'Returns all segments when :all passed' do
      res = @domain.segments
      expect(res).to be_an_instance_of(Array)
    end

    it 'Returns specific segment when segment ID passed' do
      s = @domain.segments(@segment_name)
      expect(@segment.uri).to eq s.uri
      expect(s).to be_an_instance_of(GoodData::Segment)
      expect(@segment).to be_an_instance_of(GoodData::Segment)
    end
  end

  describe '#delete' do
    it 'Deletes particular segment' do
      old_count = @domain.segments.count
      s = @domain.segments(@segment_name)
      s.delete
      expect(@domain.segments.length).to eq(old_count - 1)
      # prevent delete attempt in the after hook
      @segment = nil
    end
  end

  describe '#save' do
    after do
      @different_master.delete if @different_master
      @different_data_product.delete if @different_data_product
    end

    it 'can update a segment master project' do
      @different_master = @client.create_project(title: 'Test project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      @segment.master_project = @different_master
      @segment.save
      @segment = @domain.segments(@segment_name)
      expect(@segment.master_project_uri).not_to eq @master_project.uri
      expect(@segment.master_project_uri).to eq @different_master.uri
    end

    it 'cannot update a segment id' do
      @segment.segment_id = 'different_id'
      expect do
        @segment.save
      end.to raise_error RestClient::BadRequest
    end
  end

  describe '#create_client' do
    after do
      @client_project && @client_project.delete
      @segment_client && @segment_client.delete
    end

    it 'can create a new client in a segment' do
      @client_project = @client.create_project(title: 'client_1 project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      @segment_client = @segment.create_client(id: 'tenant_1', project: @client_project)
      expect(@segment_client).to be_an_instance_of(GoodData::Client)
      expect(@segment.clients.count).to eq 1
    end
  end

  describe '#provision_client_projects' do
    it 'returns an enumerable result' do
      result = @segment.provision_client_projects
      expect(result).to be_an_instance_of(Enumerator)
    end
  end
end
