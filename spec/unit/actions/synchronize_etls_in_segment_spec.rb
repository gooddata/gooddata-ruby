# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'

describe GoodData::LCM2::SynchronizeETLsInSegment do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }

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

    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        organization: domain,
        synchronize: [{ segment_id: 'some_segment_ids' }]

      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(gdc_gd_client).to receive(:domain) { domain }
      allow(domain).to receive(:segments) { segment }
      allow(segment).to receive(:synchronize_processes) { result }
    end

    it 'raise error' do
      expect { subject.class.call(params) }.to raise_error
    end
  end
end
