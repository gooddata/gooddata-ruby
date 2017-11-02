# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/models/segment'
require 'securerandom'

describe GoodData::DataProduct do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  before(:each) do
    @uuid = SecureRandom.uuid
    @data_product_id = "data-product-#{@uuid}"
    @data_product = @domain.create_data_product(id: @data_product_id)
  end

  after(:each) do
    @data_product && @data_product.delete(force: true)
  end

  after(:all) do
    @client.disconnect
  end

  describe '#[]' do
    it 'Returns all data products when :all passed' do
      res = @domain.data_products
      expect(res).to be_an_instance_of(Array)
    end

    it 'Returns specific data product when data product ID passed' do
      data_product = @domain.data_products(@data_product_id)
      expect(data_product.uri).to eq @data_product.uri
      expect(data_product).to be_an_instance_of(GoodData::DataProduct)
    end
  end

  describe '#delete' do
    it 'Deletes particular data product' do
      old_count = @domain.data_products.count
      @data_product.delete
      expect(@domain.data_products.length).to eq(old_count - 1)
      # prevent delete attempt in the after hook
      @data_product = nil
    end
  end

  describe '#save' do
    it 'can update a data product id' do
      @data_product.data_product_id = 'different_id'
      @data_product.save
    end
  end

  describe '#create_segment' do
    before do
      @master_project = @client.create_project(title: "Test MASTER project for #{@uuid}", auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
    end

    it 'creates a segment' do
      segment = @data_product.create_segment(segment_id: "test-segment-#{@uuid}", master_project: @master_project)
      expect(segment).to be_instance_of GoodData::Segment
      expect(segment.data_product.data_product_id).to eq(@data_product_id)
    end
  end
end
