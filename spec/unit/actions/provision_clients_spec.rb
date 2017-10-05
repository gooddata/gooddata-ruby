# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/provision_clients'
require 'gooddata/lcm/actions/purge_clients'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::ProvisionClients do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:logger) { double('logger') }
  let(:segment) { double('segment') }

  before do
    allow(gdc_gd_client).to receive(:domain).and_return(domain)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:error).and_return({})
    allow(segment).to receive(:segment_id).and_return({})
    allow(domain).to receive(:provision_client_projects).and_raise('limit reached')
  end

  context 'when provisioning get errors' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        gdc_logger: logger,
        segments: [
          segment
        ]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'clean all zombie clients ' do
      expect(GoodData::LCM2::PurgeClients).to receive(:call).and_return(results: [], params: { client_projects: [] })
      expect { subject.class.call(params) }.to raise_error('limit reached')
    end
  end
end
