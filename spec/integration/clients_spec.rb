# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::Client do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    @master_project = @client.create_project(title: 'Test project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
    @segment_name = "segment-#{SecureRandom.uuid}"
    @segment = @domain.create_segment(segment_id: @segment_name, master_project: @master_project)
  end

  after(:all) do
    @segment && @segment.delete
    @master_project && @master_project.delete
    @client.disconnect
  end

  describe '#[]' do
    before(:all) do
      client_id = SecureRandom.uuid
      @client_project = @client.create_project(title: "client_#{client_id} project", auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{client_id}", project: @client_project)
    end

    it 'Returns all clients of a segment' do
      clients = @segment.clients
      expect(clients.to_a).to be_an_instance_of(Array)
      expect(clients.to_a.size).to eq 1
    end

    it 'Returns specific tenant when schedule ID passed' do
      client = @segment.clients(@segment_client)
      expect(client).to be_an_instance_of(GoodData::Client)
      expect(client.uri).to eq @segment_client.uri
    end

    after(:all) do
      @client_project && @client_project.delete
      @segment_client && @segment_client.delete
    end
  end

  describe '#delete' do
    before(:all) do
      client_id = SecureRandom.uuid
      @segment_client = @segment.create_client(id: "tenant_#{client_id}")
    end

    it 'Deletes particular client' do
      expect(@segment.clients.count).to eq 1
      s = @segment.clients(@segment_client)
      s.delete
      expect(@segment.clients.count).to eq 0
      @segment_client = nil
    end
  end

  describe '#delete' do
    before(:all) do
      client_id = SecureRandom.uuid
      @client_project = @client.create_project(title: 'client_1 project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{client_id}", project: @client_project)
    end

    it 'Deletes particular client. Project is cleaned up as well' do
      expect(@segment.clients.count).to eq 1
      s = @segment.clients(@segment_client)
      s.delete
      expect(@segment.clients.count).to eq 0
      expect(@client_project.reload!.state).to eq :deleted
      @segment_client = nil
    end
  end

  describe '#save' do
    before(:all) do
      @client_id = SecureRandom.uuid
      @client_project = @client.create_project(title: 'client_1 project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{@client_id}", project: @client_project)
    end

    it 'can update project id' do
      begin
        other_client_project = @client.create_project(title: "client_#{@client_id} other project", auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
        @segment_client.project = other_client_project
        @segment_client.save
        expect(@segment.clients(@segment_client).project_uri).to eq other_client_project.uri
      ensure
        other_client_project && other_client_project.delete
      end
    end

    it 'throws error when trying to update tenants segment id' do
      second_segment_name = "segment-#{SecureRandom.uuid}"
      second_master_project = @client.create_project(title: 'Test project', auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
      second_segment = @domain.create_segment(segment_id: second_segment_name, master_project: second_master_project)
      @segment_client.segment = second_segment

      expect do
        @segment_client.save
      end.to raise_error(RestClient::BadRequest)
    end

    it 'cannot update a client id' do
      @segment_client.client_id = 'different_id'
      expect do
        @segment_client.save
      end.to raise_error RestClient::BadRequest
    end

    after(:all) do
      @segment_client && @segment_client.delete
      @client_project && @client_project.delete
    end
  end
end
