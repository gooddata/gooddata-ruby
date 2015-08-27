# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Project do
  before(:all) do
    @client = ConnectionHelper::create_default_connection
    @p = GoodData::Project.create_object(title: 'a', client: @client)
    @domain = @client.domain('dummy_domain')
    @roles = [
      GoodData::ProjectRole.create_object(title: 'Test Role',
                                          summary: 'Test role summary',
                                          identifier: 'test_role',
                                          uri: '/roles/1',
                                          permissions: {
                                            "canManageFact" => "1",
                                            "canListInvitationsInProject" => "1"
                                          }),
      GoodData::ProjectRole.create_object(title: 'Test Role 2',
                                          summary: 'Test role 2 summary',
                                          identifier: 'test_role_2',
                                          uri: '/roles/2',
                                          permissions: {
                                            "canManageFact" => "1"
                                          })
    ]
    @domain_members = [
      GoodData::Profile.create_object(login: 'john.doe+in_domain@gooddata.com', uri: '/uri/john_domain'),
    ]
    @members = [
      GoodData::Membership.create(login: 'john.doe@goodadta.com', uri: '/uri/john'),
      GoodData::Membership.create(login: 'jane.doe@goodadta.com', uri: '/uri/jane')
    ]
  end

  describe 'resolve_roles' do    
    it 'Can handle case with user login when user is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles('john.doe@goodadta.com', 'test_role', project_users: @members, roles: @roles)
      expect(a).to eq "/gdc/account/profile/john.doe@goodadta.com"
      expect(b).to eq ["/roles/1"]
    end
    
    it 'Can handle case with user uri when user is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles('/uri/john', 'test_role', project_users: @members, roles: @roles)
      expect(a).to eq "/uri/john"
      expect(b).to eq ["/roles/1"]
    end
    
    it 'can handle case with info with uri when user is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles({uri: '/uri/john', first_name: 'John'}, 'test_role', project_users: @members, roles: @roles)
      expect(a).to eq "/uri/john"
      expect(b).to eq ["/roles/1"]
    end
    
    it 'can handle case with info with login when he is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles({ login: 'john.doe@goodadta.com', first_name: 'John' }, 'test_role', project_users: @members, roles: @roles)
      expect(a).to eq "/gdc/account/profile/john.doe@goodadta.com"
      expect(b).to eq ["/roles/1"]
    end
    
    it 'can handle case with member when he is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles(@members.first, 'test_role_2', project_users: @members, roles: @roles)
      expect(a).to eq "/uri/john"
      expect(b).to eq ["/roles/2"]
    end
    
    it 'can handle case with profile when the user is in the project' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles(@domain_members.first, 'test_role_2', project_users: @members, roles: @roles)
      expect(a).to eq "/uri/john_domain"
      expect(b).to eq ["/roles/2"]
    end

    it 'Can handle case with user login when user is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles('john.doe+in_domain@gooddata.com', 'test_role', project_users: [], domain_users: @domain_members, roles: @roles, domain: @domain)
      expect(a).to eq "/gdc/account/profile/john.doe+in_domain@gooddata.com"
      expect(b).to eq ["/roles/1"]
    end

    it 'Can handle case with user uri when user is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles('/uri/john_domain', 'test_role', project_users: [], domain_users: @domain_members, roles: @roles, domain: @domain)
      expect(a).to eq "/uri/john_domain"
      expect(b).to eq ["/roles/1"]
    end

    it 'can handle case with info with uri when user is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles({uri: '/uri/john_domain', first_name: 'John'}, 'test_role', project_users: [], domain_users: @domain_members, roles: @roles, domain: @domain)
      expect(a).to eq "/uri/john_domain"
      expect(b).to eq ["/roles/1"]
    end

    it 'can handle case with info with login when he is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles({ login: 'john.doe+in_domain@gooddata.com', first_name: 'John' }, 'test_role', project_users: [], domain_users: @domain_members, roles: @roles, domain: @domain)
      expect(a).to eq "/gdc/account/profile/john.doe+in_domain@gooddata.com"
      expect(b).to eq ["/roles/1"]
    end

    it 'can handle case with member when he is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles(@domain_members.first, 'test_role_2', project_users: [], domain_users: @domain_members, roles: @roles, domain: @domain)
      expect(a).to eq "/uri/john_domain"
      expect(b).to eq ["/roles/2"]
    end

    it 'can handle case with profile when the user is in the domain' do
      # we have to provide users from project to be able to do this by login
      a, b = @p.resolve_roles(@domain_members.first, 'test_role_2', project_users: [], domain_users: @domain_members, roles: @roles)
      expect(a).to eq "/uri/john_domain"
      expect(b).to eq ["/roles/2"]
    end
  end  
end
