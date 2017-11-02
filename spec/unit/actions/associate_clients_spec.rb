# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/associate_clients'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::AssociateClients do
  DATA_PRODUCT_ID = 'data-product-id'

  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:segment) { double(:segment) }
  let(:domain) { double(:domain) }
  let(:client) { double(:client) }
  let(:data_product) { double(:data_product) }

  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(domain).to receive(:update_clients_settings)
    allow(domain).to receive(:segments) { segment }
    allow(domain).to receive(:update_clients) {}
    allow(segment).to receive(:clients) { [client] }
    allow(client).to receive(:id) { 'an-id' }
    allow(segment).to receive(:create_client) { client }
    allow(segment).to receive(:data_product) { data_product }
    allow(data_product).to receive(:data_product_id) { DATA_PRODUCT_ID }
  end

  context 'when clients parameter is passed' do
    let(:params) do
      params = {
        gdc_gd_client: gdc_gd_client,
        clients: [
          { segment: segment }
        ]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'enriches the clients with data_product_id' do
      subject.class.call(params)
      expect(params.clients.first.data_product_id).to eq(DATA_PRODUCT_ID)
    end
  end
end
