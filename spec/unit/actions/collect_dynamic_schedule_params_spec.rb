# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_dynamic_schedule_params'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::CollectDymanicScheduleParams do
  let(:data_source) { double(:data_source) }

  context 'when dynamic schedule params are passed' do
    let(:params) do
      GoodData::LCM2.convert_to_smart_hash(
        dynamic_params: {
          input_source: {}
        }
      )
    end

    before do
      allow(GoodData::Helpers::DataSource).to receive(:new).and_return(data_source)
      allow(data_source).to receive(:realize).and_return('spec/data/dynamic_schedule_params_table.csv')
    end

    it 'collects them' do
      result = GoodData::LCM2.run_action(subject.class, params)
      expected = {
        'client_1' => {
          'rollout' => {
            'MODE' => 'mode_a'
          },
          all_schedules: {
            'MODE' => 'mode_x'
          },
          'release' => {
            'MODE' => 'mode_c'
          }
        },
        'client_2' => {
          'provisioning' => {
            'MODE' => 'mode_b'
          }
        },
        all_clients: {
          all_schedules: {
            'MODE' => 'mode_all'
          }
        }
      }
      expect(result[:params][:schedule_params]).to eq(expected)
    end

    it 'does not print the one with param_secure' do
      result = GoodData::LCM2.run_action(subject.class, params)
      secret_param_value = 'mode_a'
      public_param_value = 'mode_c'

      result[:results].each do |r|
        expect(r['param_value']).not_to eq(secret_param_value)
      end
      expect(result[:results].map { |r| r['param_value'] }).to include(public_param_value)
    end
  end
end
