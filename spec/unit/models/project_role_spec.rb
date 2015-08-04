# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/project'
require 'gooddata/models/project_role'

describe GoodData::ProjectRole do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project(:client => @client)
    @roles = @project.roles
    @role = @roles.first
  end

  after(:all) do
    @client.disconnect
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      res = @role.author
      expect(res).to be_an_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      res = @role.contributor
      expect(res).to be_an_instance_of(GoodData::Profile)
    end
  end

  describe '#created' do
    it 'Returns created date as Time' do
      res = @role.created
      expect(res).to be_an_instance_of(Time)
    end
  end

  describe '#identifier' do
    it 'Returns identifier as String' do
      res = @role.identifier
      expect(res).to be_an_instance_of(String)
    end
  end

  describe '#permissions' do
    it 'Returns summary as Hash' do
      res = @role.permissions
      expect(res).to be_an_instance_of(Hash)
    end
  end

  describe '#summary' do
    it 'Returns summary as String' do
      res = @role.summary
      expect(res).to be_an_instance_of(String)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      res = @role.title
      expect(res).to be_an_instance_of(String)
    end
  end

  describe '#updated' do
    it 'Returns updated date as Time' do
      res = @role.updated
      expect(res).to be_an_instance_of(Time)
    end
  end

  describe '#uri' do
    it 'Returns URI as String' do
      res = @role.uri
      expect(res).to be_an_instance_of(String)
    end
  end

  describe '#users' do
    it 'Returns users as Array<GoodData::Profile>'
    # it 'Returns users as Array<GoodData::Profile>' do
    #   res = @role.users
    #   expect(res).to be_an_instance_of(Array)
    #   res.each do |user|
    #     expect(user).to be_an_instance_of(GoodData::Profile)
    #   end
    # end
  end
end
