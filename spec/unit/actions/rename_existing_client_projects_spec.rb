# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'

describe GoodData::LCM2::RenameExistingClientProjects do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:client) { double('client') }
  let(:project) { double('project') }

  context 'client project is existing in input source' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        organization: domain,
        clients: [
          {
            id: 'Id',
            settings: [
              {
                name: 'lcm.title',
                value: 'renamed project'
              }
            ]
          }
        ],
        client_projects: {
          'Id' => { segment_client: client, project: project }
        }
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(gdc_gd_client).to receive(:domain) { domain }
      allow(client).to receive(:project) { project }
      allow(project).to receive(:pid) { '123456789' }
      allow(project).to receive(:title) { "old project" }
      allow(project).to receive(:title=)
      allow(project).to receive(:save)
    end

    it 'rename client project title' do
      expect(project).to receive(:title=).with('renamed project')
      result = subject.class.call(params)
      expect(result).to eq [{ id: 'Id', pid: '123456789', old_title: 'old project', new_title: 'renamed project' }]
    end
  end
end
