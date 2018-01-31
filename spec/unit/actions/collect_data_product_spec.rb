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
  let(:gdc_logger) { double(:gdc_logger) }
  let(:data_product) { GoodData::DataProduct.new({}) }

  before do
    allow(client).to receive(:domain) { domain }
    allow(gdc_logger).to receive(:info)
    allow(domain).to receive(:data_products) { data_product }
  end

  context 'when data_product parameter is passed' do
    let(:data_product_id) { 'data-product' }
    let(:params) do
      params = {
        gdc_gd_client: client,
        gdc_logger: gdc_logger,
        data_product: data_product_id
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'collects the specified data_product object' do
      expect(domain).to receive(:data_products).with(data_product_id)
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

    it "collects the 'default' data_product" do
      expect(domain).to receive(:data_products).with('default')
      result = subject.class.call(params)
      expect(result[:params][:data_product]).to be_a GoodData::DataProduct
    end

    context 'when default data product does not exist in domain' do
      before do
        allow(domain).to receive(:data_products) { nil }
      end

      it 'collects nil for backwards compatibility' do
        result = subject.class.call(params)
        expect(result[:params][:data_product]).to be_nil
      end
    end
  end
end
