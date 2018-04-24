# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::CollectDataProduct do
  let(:client) { double(:client) }
  let(:domain) { double(:domain) }
  let(:gdc_logger) { double(:gdc_logger) }
  let(:data_product) { GoodData::DataProduct.new({}) }
  let(:params) do
    params = {
      domain: domain,
      gdc_gd_client: client,
      gdc_logger: gdc_logger,
      data_product: data_product_id
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(client).to receive(:domain) { domain }
    allow(gdc_logger).to receive(:info)
    allow(domain).to receive(:data_products) { data_product }
  end

  context 'when data_product parameter is passed' do
    let(:data_product_id) { 'data-product' }

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
        gdc_logger: gdc_logger,
        domain: domain
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it "collects the 'default' data_product" do
      expect(domain).to receive(:data_products).with('default')
      result = subject.class.call(params)
      expect(result[:params][:data_product]).to be_a GoodData::DataProduct
    end
  end

  context 'when the passed data_product does not exist' do
    let(:data_product_id) { 'non-existing-data-product' }

    before do
      allow(domain).to receive(:data_products) { fail RestClient::BadRequest }
    end

    it 'creates the data product' do
      expect(domain).to receive(:create_data_product).with(id: data_product_id)
      subject.class.call(params)
    end
  end
end
