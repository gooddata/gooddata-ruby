# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::LifeCycle::Client do
  TOKEN = 'mustangs'

  before(:all) do
    @client = GoodData.connect('mustang@gooddata.com', 'jindrisska', server: 'https://mustangs.intgdc.com', verify_ssl: false )
    @master_project = @client.create_project(title: 'Test project', auth_token: TOKEN)
    @domain = @client.domain('mustangs')
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
      @client_project = @client.create_project(title: "client_#{client_id} project", auth_token: TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{client_id}", project: @client_project)
    end

    it 'Returns all clients of a segment' do
      clients = @segment.clients
      expect(clients.to_a).to be_an_instance_of(Array)
      expect(clients.to_a.count).to eq 1
    end

    it 'Returns specific tenant when schedule ID passed' do
      client = @segment.clients(@segment_client.uri)
      expect(client).to be_an_instance_of(GoodData::LifeCycle::Client)
      expect(client.uri).to eq @segment_client.uri
    end

    after(:all) do
      @segment_client && @segment_client.delete
      @client_project && @client_project.delete
    end

  end

  describe '#delete' do
    before(:all) do
      client_id = SecureRandom.uuid
      @client_project = @client.create_project(title: 'client_1 project', auth_token: TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{client_id}", project: @client_project)
    end

    it 'Deletes particular client' do
      expect(@segment.clients.count).to eq 1
      s = @segment.clients(@segment_client.uri)
      s.delete
      expect(@segment.clients.count).to eq 0
      @segment_client = nil
      @client_project = nil
    end

    after(:all) do
      @client_project && @client_project.delete
    end
  end

  describe '#save' do
    before(:all) do
      @client_id = SecureRandom.uuid
      @client_project = @client.create_project(title: 'client_1 project', auth_token: TOKEN)
      @segment_client = @segment.create_client(id: "tenant_#{@client_id}", project: @client_project)
    end

    it 'can update project id' do
      begin
        other_client_project = @client.create_project(title: "client_#{@client_id} other project", auth_token: TOKEN)
        @segment_client.project = other_client_project
        @segment_client.save
        expect(@segment.clients('tenant_1').project_uri).to eq other_client_project.uri
      ensure
        other_client_project && other_client_project.delete
      end
    end

    it 'can update tenants segment id' do
      second_segment_name = "segment-#{SecureRandom.uuid}"
      second_master_project = @client.create_project(title: 'Test project', auth_token: TOKEN)
      second_segment = @domain.create_segment(segment_id: second_segment_name, master_project: second_master_project)
      @segment_client.segment = second_segment
      @segment_client.save
      expect(second_segment.clients.find { |s| s.uri == @segment_client.uri }).not_to be_nil
      expect(@segment.clients.find { |s| s.uri == @segment_client.uri }).to be_nil
    end

    it 'cannot update a client id' do
      @segment_client.client_id = 'different_id'
      expect {
        @segment_client.save
      }.to raise_error RestClient::BadRequest
    end

    after(:all) do
      @segment_client && @segment_client.delete
      @client_project && @client_project.delete
    end
  end
end
