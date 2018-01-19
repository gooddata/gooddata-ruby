# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::UserFilterBuilder do
  describe '.execute_mufs' do
    let(:login) { 'rubydev+admin@gooddata.com' }
    let(:full_definition_filter) do
      {
        :login => login,
        :filters => [{
          :label => label_id,
          :over => nil,
          :to => nil,
          :values => ["Washington"]
        }]
      }
    end

    let(:label_id) { 'label.csv_policies.state' }
    let(:label_uri) { '/gdc/md/wock3futg594lz3ornqv70yvbsivf896/obj/270' }
    let(:filter_definitions) { [full_definition_filter] }
    let(:options) do
      { client: client, project: project }
    end
    let(:users_brick_input) { [{ 'login' => login }] }
    let(:client) { double('client') }
    let(:project) { double('project') }
    let(:user) { double('user') }
    let(:project_users) { [user] }
    let(:label) { double('label') }
    let(:filter) { double('filter') }
    let(:existing_filter) { double('existing_filter') }
    let(:profile_url) { '/gdc/account/profile/foo' }

    before do
      allow(project).to receive(:labels)
        .and_return([label])
      allow(project).to receive(:labels)
        .and_return([label])
      allow(project).to receive(:attributes)
      allow(project).to receive(:users).and_return(project_users)
      allow(project).to receive(:data_permissions).and_return([existing_filter])
      allow(project).to receive(:pid)
      allow(label).to receive(:values_count).and_return(666_666)
      allow(label).to receive(:uri).and_return(label_uri)
      allow(label).to receive(:find_value_uri).with('Washington').and_return('foo')
      allow(label).to receive(:attribute_uri).and_return('bar')
      allow(label).to receive(:identifier).and_return(label_id)
      allow(client).to receive(:create).and_return(filter)
      allow(client).to receive(:get)
        .and_return('userFilters' => { 'items' => [] })
      allow(client).to receive(:post)
        .and_return('userFiltersUpdateResult' => [])
      allow(filter).to receive(:related_uri)
      allow(existing_filter).to receive(:related_uri)
      allow(filter).to receive(:save)
      allow(filter).to receive(:uri)
      allow(user).to receive(:login).and_return(login)
      allow(user).to receive(:profile_url).and_return(login)
    end

    it 'resolves mufs to be created/deleted' do
      expect(existing_filter).to receive(:delete)
      result = subject.execute_mufs(filter_definitions, options)
      expect(result[:created].length).to be(1)
      expect(result[:deleted].length).to be(1)
    end

    context 'when users_brick_input option specified' do
      let(:user) { double('user') }
      let(:users_brick_input) { [{ 'login' => login }] }
      let(:options) do
        { client: client,
          project: project,
          users_brick_input: users_brick_input }
      end
      before do
        allow(project).to receive(:users).and_return([user])
        allow(user).to receive(:login).and_return(login)
        allow(user).to receive(:profile_url).and_return(profile_url)
      end

      context 'when filter has user in users_brick_input' do
        before do
          allow(existing_filter).to receive(:json)
            .and_return(related: profile_url)
        end
        it 'deletes the filter' do
          expect(existing_filter).to receive(:delete)
          result = subject.execute_mufs(filter_definitions, options)
          expect(result[:deleted].length).to be(1)
        end
      end

      context 'when filter does not have user in users_brick_input' do
        before do
          allow(existing_filter).to receive(:json)
            .and_return(related: 'not_in_users_brick_input')
        end

        it 'does not delete filter' do
          result = subject.execute_mufs(filter_definitions, options)
          expect(result[:deleted]).to be_empty
        end
      end
    end
  end
end
