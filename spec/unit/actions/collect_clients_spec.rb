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

  before do
    allow(GoodData::Helpers::DataSource).to receive(:new)
      .and_return(data_source)
    allow(data_source).to receive(:realize)
      .and_return('spec/data/workspace_table.csv')
  end

  context 'when segments is specified' do
    let(:params) do
      params = {
        segments: [{ segment_id: 'segment_foo' }],
        input_source: {}
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'collects clients from the specified segment' do
      result = subject.class.call(params)
      expected = [{ client: 'client_foo',
                    segment_id: 'segment_foo',
                    title: nil }]
      expect(result[:results]).to eq(expected)
    end
  end

  context 'when segment_names is an empty array' do
    let(:params) do
      params = {
        segments: [],
        input_source: {}
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'collects clients from all segments' do
      result = subject.class.call(params)
      expect(result[:results].length).to be 2
    end
  end
end
