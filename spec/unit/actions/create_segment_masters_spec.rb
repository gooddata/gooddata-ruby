# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_segment_clients'
require 'gooddata/lcm/lcm2'
require_relative '../datawarehouse_mock'

describe GoodData::LCM2::CreateSegmentMasters do
  let(:gdc_gd_client) { double_with_class(GoodData::Rest::Client) }
  let(:ads_client) { double_with_class(GoodData::Datawarehouse) }
  let(:development_client) { double_with_class(GoodData::Rest::Client) }
  let(:gdc_logger) { double_with_class(Logger) }
  let(:project) { double('project') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:segments) { [segment] }
  let(:data_product) { double_with_class(GoodData::DataProduct) }

  before do
    allow(development_client).to receive(:projects) { true }
    allow(gdc_logger).to receive(:info) {}
    allow(gdc_gd_client).to receive(:create_project) { project }
    allow(project).to receive(:pid) { '123' }
    allow(segment).to receive(:synchronize_clients) {}
    allow(data_product).to receive(:create_segment) { segment }
    allow(data_product).to receive(:data_product_id) { 'default' }
    allow(segment).to receive(:master_project) {}
    allow(segment).to receive(:master_project=) {}
    allow(segment).to receive(:save) {}
    allow(project).to receive(:json) { {} }
  end

  context 'when parametrizing project environment' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [{ segment_id: 'segment_foo', driver: 'Pg', master_name: 'name' }],
        tokens: { pg: 'pgtoken' },
        ads_client: ads_client,
        domain: domain,
        development_client: development_client,
        gdc_logger: gdc_logger,
        project_environment: 'DEVELOPMENT',
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(ads_client).to receive(:execute_select) { [{ version: '1.2' }] }
      allow(gdc_gd_client).to receive(:domain) { domain }
      allow(domain).to receive(:segments) { [] }
      allow(domain).to receive(:create_segment) {}
    end

    it 'passes the argument to create_project' do
      expect(gdc_gd_client).to receive(:create_project).with(
        title: 'name',
        auth_token: 'pgtoken',
        driver: 'Pg',
        environment: 'DEVELOPMENT'
      )
      subject.class.call(params)
    end
  end

  context 'when ads_output_stage_prefix parameter specified' do
    let(:prefix) { '(^_^)' }
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        synchronize: [{}],
        segments: [{
          segment_id: 'segment_foo',
          driver: 'Pg',
          master_name: 'name',
          development_pid: 'qwertyuiop',
          ads_output_stage_prefix: prefix
        }],
        tokens: { pg: 'pgtoken' },
        ads_client: ads_client,
        domain: 'robocalypse-technology',
        development_client: development_client,
        gdc_logger: gdc_logger,
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(gdc_gd_client).to receive(:domain).and_return(domain)
      allow(domain).to receive(:segments) { [] }
      allow(GoodData::LCM2::Helpers).to receive(:latest_master_project)
      allow(ads_client).to receive(:execute_select) { [{ version: '1.2' }] }
    end

    it 'passes ads_output_stage_prefix parameter' do
      result = GoodData::LCM2.run_action(subject.class, params)
      actual = result[:params][:synchronize].first[:ads_output_stage_prefix]
      expect(actual).to eq(prefix)
    end
  end
end
