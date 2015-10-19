# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::LifeCycle::Segment do
  TOKEN = 'mustangs'

  before(:all) do
    @client = GoodData.connect('mustang@gooddata.com', 'jindrisska', server: 'https://mustangs.intgdc.com', verify_ssl: false )
    @domain = @client.domain('mustangs')
  end

  before(:each) do
    @uuid = SecureRandom.uuid
    @master_project = @client.create_project(title: "Test MASTER project for #{@uuid}", auth_token: TOKEN)
    @segment_name = "segment-#{@uuid}"
    @segment = @domain.create_segment(segment_id: @segment_name, master_project: @master_project)
  end

  after(:each) do
    @segment && @segment.delete
  end

  after(:all) do
    @client.disconnect
    @master_project.delete
  end

  describe '#[]' do
    it 'Returns all segments when :all passed' do
      res = @domain.segments
      expect(res).to be_an_instance_of(Array)
    end

    it 'Returns specific segment when segment ID passed' do
      s = @domain.segments(@segment_name)
      @segment.uri == s.uri
      expect(s).to be_an_instance_of(GoodData::LifeCycle::Segment)
      expect(@segment).to be_an_instance_of(GoodData::LifeCycle::Segment)
    end
  end

  describe '#delete' do
    it 'Deletes particular segment' do
      old_count = @domain.segments.count
      s = @domain.segments(@segment_name)
      s.delete
      expect(@domain.segments.length).to eq (old_count - 1)
      # prevent delete attempt in the after hook
      @segment = nil
    end
  end

  describe '#save' do
    it 'can update a segment master project' do
      different_master = @client.create_project(title: 'Test project', auth_token: TOKEN)
      @segment.master_project = different_master
      @segment.save
      @segment = @domain.segments(@segment_name)
      expect(@segment.master_project_uri).not_to eq @master_project.uri
      expect(@segment.master_project_uri).to eq different_master.uri
    end

    it 'cannot update a segment id' do
      @segment.segment_id = 'different_id'
      expect {
        @segment.save
      }.to raise_error RestClient::BadRequest
    end
  end

  describe '#create_client' do
    it 'can create a new client in a segment' do
      begin
        client_project = @client.create_project(title: 'client_1 project', auth_token: TOKEN)
        segment_client = @segment.create_client(id: 'tenant_1', project: client_project)
        expect(segment_client).to be_an_instance_of(GoodData::LifeCycle::Client)
        expect(@segment.clients.count).to eq 1
      ensure
        segment_client && segment_client.delete
        client_project && client_project.delete
      end
    end
  end
end
