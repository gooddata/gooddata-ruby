# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::Segment do
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
    @segment && @segment.delete(force: true)
  end

  after(:all) do
    @master_project.delete if @master_project
    @client.disconnect
  end

  describe '#[]' do
    it 'Returns all segments when :all passed' do
      res = @domain.segments
      expect(res).to be_an_instance_of(Array)
    end

    it 'Returns specific segment when segment ID passed' do
      s = @domain.segments(@segment_name)
      @segment.uri == s.uri
      expect(s).to be_an_instance_of(GoodData::Segment)
      expect(@segment).to be_an_instance_of(GoodData::Segment)
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
        expect(segment_client).to be_an_instance_of(GoodData::Client)
        expect(@segment.clients.count).to eq 1
      ensure
        segment_client && segment_client.delete
      end
    end
  end

  describe '#provision_client_projects' do
    it 'can create a new client in a segment without project and then provision' do
      begin
        segment_client = @segment.create_client(id: 'tenant_1')
        expect(segment_client).to be_an_instance_of(GoodData::Client)
        expect(@segment.clients.count).to eq 1
        @domain.synchronize_clients
        @domain.provision_client_projects
        expect(@domain.segments.flat_map { |s| s.clients.to_a }.all?(&:project?)).to be_truthy
      ensure
        segment_client && segment_client.delete
      end
    end
  end

  describe '#update_clients' do
    it 'can create a new client in a segment without project and then provision' do
      begin
        uuid_2 = SecureRandom.uuid
        master_project_2 = @client.create_project(title: "Test MASTER project for #{uuid_2}", auth_token: TOKEN)
        segment_name_2 = "segment-#{uuid_2}"
        segment_2 = @domain.create_segment(segment_id: segment_name_2, master_project: master_project_2)

        client_1 = "client-#{SecureRandom.uuid}"
        client_2 = "client-#{SecureRandom.uuid}"
        data = [{id: client_1, segment: segment_name_2 },
                {id: client_2, segment: @segment_name }]
        res = @domain.update_clients(data)
        expect(@domain.segments.map(&:id)).to include(@segment.id, segment_2.id)
        expect(@domain.segments.pmapcat {|s| s.clients.to_a }.map(&:id)).to include(client_1, client_2)

        client_3 = "client-#{SecureRandom.uuid}"
        client_4 = "client-#{SecureRandom.uuid}"
        data = [{id: client_3, segment: segment_name_2 },
                {id: client_4, segment: @segment_name }]
        res = @domain.update_clients(data)
        expect(@domain.segments.pmapcat {|s| s.clients.to_a }.map(&:id)).to include(client_1, client_2, client_3, client_4)

        # bring the projects
        @domain.synchronize_clients
        @domain.provision_client_projects
        projects_to_delete = @domain.segments.pmapcat {|s| s.clients.to_a }.select { |c| [client_1, client_2].include?(c.id) }.map(&:project)
        res = @domain.update_clients(data, delete_extra: true)
        expect(@domain.segments.pmapcat {|s| s.clients.to_a }.map(&:id)).to include(client_3, client_4)
        expect(@domain.segments.pmapcat {|s| s.clients.to_a }.map(&:id)).not_to include(client_1, client_2)
        expect(projects_to_delete.pmap(&:reload!).map(&:state)).to eq [:deleted, :deleted]
      ensure
        segment_2.delete(force: true) if segment_2
      end
    end
  end
end
