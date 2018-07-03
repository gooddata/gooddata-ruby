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
  let(:segment_mock) { double('segment') }
  let(:segments) { [segment_mock] }
  let(:client) { double('client') }
  let(:clients) { [client] }
  let(:project) { double(GoodData::Project) }
  let(:master_project_id) { 'master_project_id' }

  let(:converted_params) { GoodData::LCM2.convert_to_smart_hash(params) }

  subject do
    GoodData::LCM2.run_action(
      GoodData::LCM2::CollectSegmentClients,
      converted_params
    )
  end

  before do
    allow(gdc_gd_client).to receive(:domain).and_return(domain)
    allow(domain).to receive(:segments).and_return(segments)
    allow(segment_mock).to receive(:clients).and_return(clients)
    allow(project).to receive(:pid)
    allow(project).to receive(:title)
    allow(gdc_gd_client).to receive(:projects).with(master_project_id).and_return(project)
    allow(gdc_gd_client).to receive(:class) { GoodData::Rest::Client }
  end

  context 'when client has no project in segments' do
    let(:params) do
      {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [{}]
      }
    end

    before do
      allow(client).to receive(:project?).and_return(false)
      allow(client).to receive(:client_id).and_return('my_client_id')
    end

    it 'raise error' do
      expect { subject }.to raise_error
    end
  end

  context 'when client has project in segments' do
    let(:client_project) { double(GoodData::Project) }
    let(:segment_master_project) { double(GoodData::Project) }
    let(:segment) do
      { segment_id: 'premium_segment',
        development_pid: 'dev_project',
        master_name: 'master_1',
        segment: segment_mock,
        segment_master: segment_master_project }
    end
    let(:ads_client) { double('ads_client') }
    let(:ads_response) do
      [
        {
          master_project_id: master_project_id
        }
      ]
    end
    let(:params) do
      {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [segment],
        domain: domain,
        ads_client: ads_client
      }
    end

    before do
      allow(client).to receive(:project).and_return(client_project)
      allow(client).to receive(:project?).and_return(true)
      allow(client).to receive(:client_id).and_return('client_id')
      allow(segment_mock).to receive(:segment_id).and_return('segment-id')
      allow(ads_client).to receive(:execute_select).and_return(ads_response)
      allow(client_project).to receive(:pid)
      allow(client_project).to receive(:title)
      module GoodData
        class Datawarehouse
          # to make the test work for Rubies other than JRuby
        end
      end
      allow(ads_client).to receive(:class) { GoodData::Datawarehouse }
      allow(segment_master_project).to receive(:pid)
    end

    it 'uses the project from client in segments' do
      expect(client).to receive(:project)
      subject
    end

    context 'when there are multiple master project versions' do
      let(:latest_master_project) { double(GoodData::Project) }
      let(:latest_master_id) { 'latest_master_project_id' }
      let(:ads_response) do
        [
          {
            master_project_id: 'foo',
            version: 1
          },
          {
            master_project_id: latest_master_id,
            version: 2
          }
        ]
      end

      before do
        allow(gdc_gd_client).to receive(:projects)
          .with(latest_master_id)
          .and_return(latest_master_project)
        allow(latest_master_project).to receive(:pid)
        allow(latest_master_project).to receive(:title)
      end

      context 'when segment master is the same as latest master' do
        let(:project_pid) { 'the same' }
        before do
          allow(latest_master_project).to receive(:pid)
            .and_return(project_pid)
          allow(segment_master_project).to receive(:pid)
            .and_return(project_pid)
        end
        it 'sets previous_master parameter to nil' do
          subject[:params][:synchronize].each do |segment|
            expect(segment[:previous_master]).to eq(nil)
          end
        end
      end

      context 'when segment master is different from latest master' do
        before do
          allow(latest_master_project).to receive(:pid)
            .and_return('something')
          allow(segment_master_project).to receive(:pid)
            .and_return('something else')
        end
        it 'sets previous_master parameter to current segment master' do
          subject[:params][:synchronize].each do |segment|
            expect(segment[:previous_master]).to eq(segment_master_project)
          end
        end
      end
    end
  end
end
