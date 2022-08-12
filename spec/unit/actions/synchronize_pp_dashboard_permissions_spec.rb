# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_pp_dashboard_permission'

describe GoodData::LCM2::SynchronizePPDashboardPermissions do
  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:development_client) { double(:development_client) }
  let(:logger) { double(:logger) }

  let(:from_project) { double(:from_project) }
  let(:to_project) { double(:to_project) }

  let(:source_dashboards) { [GoodData::Dashboard] }
  let(:target_dashboards) { [GoodData::Dashboard] }

  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      development_client: development_client,
      synchronize: [{
        segment_id: 'some_segment_ids',
        from: 'from_project_id',
        to: [{ pid: 'to_project_id' }]
      }],
      gdc_logger: logger
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    user_groups = [{
       'userGroup' => {
           'content' => {
               'name' => 'user_group_name',
               'description' => '',
               'project' => '',
               'domain' => '',
               'id' => 'user_group_id'
           },
           'meta' => {
               'created' => '',
               'updated' => ''
           },
           'links' => {
               'self' => 'user_group_uri',
               'members' => 'user_group_uri/members',
               'modifyMembers' => 'user_group_uri/modifyMembers'
           }
       }
   }]
    allow(GoodData::UserGroup).to receive(:get).and_return(user_groups)

    pp_dashboards = {
        'projectDashboard' => {
            'content' => {
                'tabs' => [],
                'filters' => []
            },
            'meta' => {
                'tags' => '',
                'summary' => '',
                'title' => 'PP Dashboard 1',
                'sharedWithSomeone' => 1
            }
        }
    }


    pp_dashboard_grantees = {
        granteeURIs: {
            items: [
                { aclEntryURI: { permission: 'read', grantee: 'user_group_uri' } }
            ]
        }
    }


    allow(GoodData::Mixin::MdGrantees).to receive(:grantees).and_return(pp_dashboard_grantees)
    allow_any_instance_of(GoodData::Mixin::MdGrantees).to receive(:change_permission).and_return(true)
    allow(logger).to receive(:info)

    allow(development_client).to receive(:projects) { from_project }
    allow(from_project).to receive(:title).and_return('src title')
    allow(from_project).to receive(:pid)


    allow(gdc_gd_client).to receive(:projects) { to_project }
    allow(to_project).to receive(:title).and_return('dest title')
    allow(to_project).to receive(:pid)

    dashboard = GoodData::Dashboard
    allow(dashboard).to receive(:title).and_return('PP Dashboard 1')
    allow(from_project).to receive(:dashboards).and_return([dashboard])
    allow(from_project).to receive(:user_groups).and_return(user_groups)
    allow(to_project).to receive(:dashboards).and_return([dashboard])
    allow(to_project).to receive(:user_groups).and_return(user_groups)

  end

  it 'should transfer Pixel Perfect dashboard permission' do
    result = [{ from_project_name: 'src title', from_project_pid: 'from_project_id', status: 'ok' }]
    expect(GoodData::Project).to receive(:transfer_dashboard_permission).with(from_project, to_project, source_dashboards, target_dashboards).and_return(result)
    subject.class.call(params)
  end
end
