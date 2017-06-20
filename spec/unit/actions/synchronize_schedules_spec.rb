# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'

describe GoodData::LCM2::SynchronizeSchedules do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:development_client) { double('development_client') }
  let(:logger) { double(info: nil, warn: nil) }
  let(:process) { double(name: 'foo', type: 'bar') }
  let(:target_project) { double(title: 'foo', pid: 'bar') }
  let(:source_project) { double(title: 'baz', pid: 'qux') }
  let(:schedule) do
    double(name: 'quux',
           disable: 'quuz',
           update_params: nil,
           update_hidden_params: nil,
           save: nil,
           enable: nil)
  end
  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      gdc_logger: logger,
      synchronize: [{
        segment_id: 'some_segment_ids',
        to: [{ pid: 'some_target_project' }]
      }],
      development_client: development_client
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:projects).and_return(target_project)
    allow(development_client).to receive(:projects).and_return(source_project)
    allow(target_project).to receive(:schedules).and_return([schedule])
    allow(GoodData::Project).to receive(:transfer_schedules)
      .and_return([{ schedule: schedule, process: process }])
    allow(schedule).to receive(:hidden_params=)
    allow(schedule).to receive(:hidden_params)
      .and_return(hidden_params)
  end

  context 'when hidden parameters not in additional_hidden_params' do
    let(:hidden_params) { { hidden_param_1: 'foo', hidden_param_2: 'bar' } }

    it 'removes the parameters' do
      expect(schedule).to receive(:hidden_params=).with({})
      subject.class.call(params)
    end

    it 'warns the user' do
      expect(logger).to receive(:warn) do |log|
        expect(log).to include('hidden_param_1', 'hidden_param_2')
      end
      subject.class.call(params)
    end
  end
end
