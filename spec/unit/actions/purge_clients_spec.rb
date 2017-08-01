# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/purge_clients'

describe GoodData::LCM2::PurgeClients do
  let(:client1) { double('client1') }
  let(:client2) { double('client2') }
  let(:project) { double('project') }

  context "some clients which don't have project or project is deleted are existing in segment" do
    let(:params) do
      params = {
        client_projects: {
          'client_id' => {
            segment_client: client1,
            project: project
          },
          'delete' => {
            segment_client: client2
          }
        }
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(client1).to receive(:project) { project }
      allow(client1).to receive(:client_id) { 'client_id' }
      allow(client2).to receive(:client_id) { 'delete' }
      allow(client1).to receive(:delete)
      allow(client2).to receive(:delete)
      allow(project).to receive(:pid) { '123456789' }
      allow(project).to receive(:deleted?) { false }
    end

    it 'purge them' do
      expect(client2).to receive(:delete)
      result = subject.class.call(params)[:results]
      expect(result).to eq [{ client_id: 'client_id', project: '123456789', status: 'ok - not purged' }, { client_id: 'delete', project: nil, status: 'purged' }]
    end
  end
end
