# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_segment_clients'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::CollectSegmentClients do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:segments) { [segment] }
  let(:client) { double('client') }
  let(:clients) { [client] }

  before do
    allow(gdc_gd_client).to receive(:domain).and_return(domain)
    allow(domain).to receive(:segments).and_return(segments)
    allow(segment).to receive(:clients).and_return(clients)
  end

  context 'when client has no project in segments' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [{}]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(client).to receive(:project?).and_return(false)
      allow(client).to receive(:client_id).and_return('my_client_id')
    end

    it 'raise error' do
      expect { subject.class.call(params) }.to raise_error
    end
  end

  context 'when client has project in segments' do
    let(:segment) { double('segment') }
    let(:project) { double('project') }
    let(:ads_client) { double('ads_client') }
    let(:ads_response) do
      [
        {
          master_project_id: 'master_project_id'
        }
      ]
    end
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [segment],
        ads_client: ads_client
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(client).to receive(:project).and_return(project)
      allow(client).to receive(:project?).and_return(true)
      allow(gdc_gd_client).to receive(:projects).with('master_project_id').and_return(project)
      allow(client).to receive(:client_id).and_return('client_id')
      allow(segment).to receive(:segment_id).and_return('segment-id')
      allow(ads_client).to receive(:execute_select).and_return(ads_response)
      allow(project).to receive(:pid)
      allow(project).to receive(:title)
    end

    it 'uses the project from client in segments' do
      expect(client).to receive(:project)
      subject.class.call(params)
    end
  end
end
