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
  let(:data_product) { double('data_product') }

  before do
    allow(gdc_gd_client).to receive(:domain).and_return(domain)
    allow(logger).to receive(:debug)
    allow(logger).to receive(:error).and_return({})
    allow(segment).to receive(:segment_id).and_return({})
    allow(segment).to receive(:provision_client_projects).and_raise('limit reached')
    allow(domain).to receive(:segments) { segment }
  end

  context 'when provisioning get errors' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        gdc_logger: logger,
        segments: [
          segment
        ],
        domain: domain,
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'clean all zombie clients' do
      expect { subject.class.call(params) }.to raise_error('limit reached')
    end
  end

  context 'when provisioning process with warning status' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        gdc_logger: logger,
        segments: [
            segment
        ],
        domain: domain,
        data_product: data_product,
        abort_on_error: false
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'process warning status' do
      allow(logger).to receive(:info)
      allow(logger).to receive(:warn)
      allow(logger).to receive(:error)

      expect(logger).to receive(:error).with(/Problem occurs when provisioning clients. Error: limit reached/)

      # Action get errors but still continue process
      subject.class.call(params)
    end
  end
end
