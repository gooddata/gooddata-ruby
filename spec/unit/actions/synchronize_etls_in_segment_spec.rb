# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'

describe GoodData::LCM2::SynchronizeETLsInSegment do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:logger) { double('logger') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      gdc_logger: logger,
      organization: domain,
      synchronize: [{
        segment_id: 'some_segment_ids',
        to: [{ pid: 'some_target_project' }]
      }]
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end
  let(:result) { { syncedResult: {} } }
  let(:target_project) { double('target_project') }

  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(domain).to receive(:segments) { segment }
    allow(segment).to receive(:synchronize_processes) { result }
    allow(gdc_gd_client).to receive(:projects).and_return(target_project)
  end

  context 'when hidden parameters not in additional_hidden_params' do
    let(:schedule) { double(:schedule) }
    let(:hidden_params) { { hidden_param_1: 'foo', hidden_param_2: 'bar' } }

    before do
      allow(target_project).to receive(:schedules).and_return([schedule])
      allow(schedule).to receive(:update_params)
      allow(schedule).to receive(:update_hidden_params)
      allow(schedule).to receive(:save)
      allow(schedule).to receive(:hidden_params)
        .and_return(hidden_params)
      allow(logger).to receive(:warn)
      allow(schedule).to receive(:hidden_params=)
      allow(schedule).to receive(:enable)
    end

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

  context 'when sync processes/schedules has problem' do
    let(:result) do
      {
        syncedResult: {
          errors: [
            {
              errorId: "91a811a7-8d3a-42d2-a1ba-024933f74021",
              errorCode: "gdc.lcm.schedule.fatal_error",
              message: "Error",
              parameters: []
            }
          ]
        }
      }
    end

    it 'raise error' do
      expect { subject.class.call(params) }.to raise_error
    end
  end
end
