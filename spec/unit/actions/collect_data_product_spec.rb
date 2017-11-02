# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::CollectDataProduct do
  it 'Has GoodData::Bricks::DefaultDataProductMiddleware class' do
    GoodData::LCM2::CollectDataProduct.should_not be(nil)
  end

  let(:client) { double(:client) }
  let(:domain) { double(:domain) }
  let(:data_product) { GoodData::DataProduct.new({}) }
  let(:gdc_logger) { double(:gdc_logger) }

  before do
    allow(client).to receive(:domain) { domain }
    allow(gdc_logger).to receive(:info) {}
  end

  context 'when data_product parameter is passed' do
    let(:params) do
      params = {
        gdc_gd_client: client,
        gdc_logger: gdc_logger,
        data_product: "data-product-#{SecureRandom.uuid}"
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(domain).to receive(:data_products) { data_product }
    end

    it 'hydrates the data_product object into params and runs the app' do
      result = subject.class.call(params)
      expect(result[:params][:data_product]).to be_a GoodData::DataProduct
    end
  end

  context 'when no data_product parameter is passed' do
    let(:params) do
      params = {
        gdc_gd_client: client,
        gdc_logger: gdc_logger
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'fallbacks to the only data_product if only one exists in the domain' do
      allow(domain).to receive(:data_products) { [data_product] }

      result = subject.class.call(params)
      expect(result[:params][:data_product]).to be_a GoodData::DataProduct
    end

    it 'fails when multiple data_products are available to fallback on' do
      allow(domain).to receive(:data_products) { [data_product, GoodData::DataProduct.new({})] }

      expect { subject.class.call(params) }.to raise_error
    end
  end
end
