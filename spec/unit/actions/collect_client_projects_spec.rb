# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/collect_client_projects'

describe GoodData::LCM2::CollectClientProjects do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:client) { double('client') }
  let(:project) { double('project') }

  context 'some clients are existing in segment' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        organization: domain,
        segments: [
          {
            segment_id: 'id'
          }
        ]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(gdc_gd_client).to receive(:domain) { domain }
      allow(domain).to receive(:segments) { [segment] }
      allow(segment).to receive(:segment_id) { 'id' }
      allow(segment).to receive(:clients) { [client] }
      allow(client).to receive(:project) { project }
      allow(client).to receive(:client_id) { 'client_id' }
      allow(project).to receive(:pid) { '123456789' }
    end

    it 'collect their projects' do
      result = subject.class.call(params)
      expect(result[:params][:client_projects]).to eq('client_id' => { segment_client: client, project: project })
      expect(result[:results]).to eq [{ client_id: 'client_id', project: '123456789' }]
    end
  end
end
