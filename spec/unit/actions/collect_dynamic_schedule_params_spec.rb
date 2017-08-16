# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_dynamic_schedule_params'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::CollectDymanicScheduleParams do
  let(:data_source) { double(:data_source) }

  before do
    allow(GoodData::Helpers::DataSource).to receive(:new).and_return(data_source)
    allow(data_source).to receive(:realize).and_return('spec/data/dynamic_schedule_params_table.csv')
  end

  context 'when dynamic schedule params are passed' do
    let(:params) do
      params = {
        dynamic_params: {
          input_source: {},
          mapping: [
            {
              name: 'mode',
              column_name: 'load_mode'
            }
          ]
        }
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'collects them' do
      result = subject.class.call(params)
      expected = {
        'client_1' => {
          'rollout' => {
            'mode' => 'mode_a'
          },
          nil => {
            'mode' => 'mode_x'
          },
          'release' => {
            'mode' => 'mode_c'
          }
        },
        'client_2' => {
          'provisioning' => {
            'mode' => 'mode_b'
          }
        },
        nil => {
          nil => {
            'mode' => 'mode_all'
          }
        }
      }
      expect(result[:params][:schedule_params]).to eq(expected)
    end
  end
end
