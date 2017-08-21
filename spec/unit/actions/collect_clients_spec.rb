# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_clients'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::CollectClients do
  let(:data_source) { double(:data_source) }
  let(:input_data) { double(:input_data) }
  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:datasource) { double(:datasource) }
  let(:project) { double(:project) }

  before do
    allow(project).to receive(:deleted?).and_return(false)
    allow(gdc_gd_client).to receive(:projects).and_return(project)
    allow(GoodData::Helpers::DataSource).to receive(:new)
      .and_return(data_source)
    allow(data_source).to receive(:realize)
      .and_return('spec/data/workspace_table.csv')
  end

  context 'when segments is specified' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        segments: [{ segment_id: 'segment_foo' }],
        input_source: {}
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'collects all clients' do
      result = subject.class.call(params)
      expected = [{ client: 'client_foo',
                    segment_id: 'segment_foo',
                    title: nil }]
      expect(result[:results]).to eq(expected)
    end
  end

  context 'when input source contains deleted project' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        segments: [{ segment_id: 'segment_foo' }],
        input_source: {}
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(project).to receive(:deleted?).and_return(true)
    end

    it 'raise error' do
      expect do
        subject.class.call(params)
      end.to raise_error(/Project 123456 of client client_foo is deleted./)
    end
  end
end
