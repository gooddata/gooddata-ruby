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
  let(:project) { double(GoodData::Project) }
  let(:master_project_id) { 'master_project_id' }

  before do
    allow(gdc_gd_client).to receive(:domain).and_return(domain)
    allow(domain).to receive(:segments).and_return(segments)
    allow(segment).to receive(:clients).and_return(clients)
    allow(project).to receive(:pid)
    allow(project).to receive(:title)
    allow(gdc_gd_client).to receive(:projects).with(master_project_id).and_return(project)
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
    let(:client_project) { double(GoodData::Project) }
    let(:segment) { double('segment') }
    let(:ads_client) { double('ads_client') }
    let(:ads_response) do
      [
        {
          master_project_id: master_project_id
        }
      ]
    end
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [segment],
        domain: domain,
        ads_client: ads_client
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(client).to receive(:project).and_return(client_project)
      allow(client).to receive(:project?).and_return(true)
      allow(client).to receive(:client_id).and_return('client_id')
      allow(segment).to receive(:segment_id).and_return('segment-id')
      allow(ads_client).to receive(:execute_select).and_return(ads_response)
      allow(client_project).to receive(:pid)
      allow(client_project).to receive(:title)
    end

    it 'uses the project from client in segments' do
      expect(client).to receive(:project)
      subject.class.call(params)
    end

    context 'when there are multiple master project versions' do
      let(:previous_master_project) { double(GoodData::Project) }
      let(:previous_master_id) { 'old_master_project_id' }
      let(:ads_response) do
        [
          {
            master_project_id: previous_master_id,
            version: 1
          },
          {
            master_project_id: master_project_id,
            version: 2
          }
        ]
      end

      before do
        allow(gdc_gd_client).to receive(:projects)
          .with(previous_master_id)
          .and_return(previous_master_project)
        allow(previous_master_project).to receive(:pid)
      end

      it 'sets diff_ldm_against parameter' do
        result = subject.class.call(params)
        result[:params][:synchronize].each do |segment|
          expect(segment[:diff_ldm_against]).to eq(previous_master_project)
        end
      end
    end
  end
end
