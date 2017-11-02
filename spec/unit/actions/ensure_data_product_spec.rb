# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/ensure_data_product'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::EnsureDataProduct do
  context 'when data_product parameter is passed' do
    let(:client) { double(:client) }
    let(:domain) { double(:domain) }
    let(:data_product) { GoodData::DataProduct.new({}) }
    let(:gdc_logger) { double(:gdc_logger) }

    let(:params) do
      params = {
        data_product: "data-product-#{SecureRandom.uuid}",
        gdc_gd_client: client,
        gdc_logger: gdc_logger
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(domain).to receive(:data_products) { raise RestClient::BadRequest }
      allow(domain).to receive(:create_data_product) { data_product }
      allow(client).to receive(:domain) { domain }
      allow(gdc_logger).to receive(:info) {}
    end

    it 'creates the data_product' do
      expect(domain).to receive(:create_data_product)
      subject.class.call(params)
    end
  end
end
