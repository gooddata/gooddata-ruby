# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require 'gooddata/lcm/actions/base_action'
require 'gooddata/lcm/actions/associate_clients'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::AssociateClients do
  DATA_PRODUCT_ID = 'data-product-id'

  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:segment) { double(:segment) }
  let(:domain) { double(:domain) }
  let(:client) { double(:client) }
  let(:data_product) { double(:data_product) }
  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      clients: [
        { segment: segment }
      ],
      domain: domain
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(gdc_gd_client).to receive(:class) { GoodData::Rest::Client }
    allow(domain).to receive(:update_clients_settings)
    allow(domain).to receive(:segments) { segment }
    allow(domain).to receive(:update_clients) {}
    allow(domain).to receive(:is_a?) { false }
    allow(domain).to receive(:is_a?).with(String) { true }
    allow(domain).to receive(:empty?) { false }
    allow(segment).to receive(:clients) { [client] }
    allow(client).to receive(:id) { 'an-id' }
    allow(segment).to receive(:create_client) { client }
    allow(segment).to receive(:data_product) { data_product }
    allow(data_product).to receive(:data_product_id) { DATA_PRODUCT_ID }
  end

  context 'when clients parameter is passed' do
    it 'enriches the clients with data_product_id' do
      GoodData::LCM2.run_action(GoodData::LCM2::AssociateClients, params)
      expect(params.clients.first.data_product_id).to eq(DATA_PRODUCT_ID)
    end
  end

  context 'when delete_extra and delete_projects parameters are passed' do
    let(:mocked_logger) { double(Logger) }

    it 'logs warning and runs' do
      local_params = params.dup
      local_params[:delete_projects] = true
      allow(GoodData).to receive(:logger).and_return(mocked_logger)
      allow(mocked_logger).to receive(:info)
      allow(mocked_logger).to receive(:warn)

      expect(mocked_logger).to receive(:warn).with(/action will not delete anything/)
      expect(domain).to receive('update_clients')
      GoodData::LCM2.run_action(GoodData::LCM2::AssociateClients, local_params)
    end
  end

  context 'when delete_mode is not in list of possible modes' do
    it 'fails' do
      local_params = params.dup
      local_params[:delete_mode] = 'some_non-existing_delete_mode'
      expect { GoodData::LCM2.run_action(GoodData::LCM2::AssociateClients, local_params) }.to raise_error(/The parameter/)
    end
  end

  context 'in any delete mode' do
    it 'runs update clients' do
      local_params = params.dup
      DELETE_MODES = %w(
        none
        delete_projects
        delete_extra
      )
      DELETE_MODES.map do |mode|
        params[:delete_mode] = mode
        expect(domain).to receive('update_clients')
        GoodData::LCM2.run_action(GoodData::LCM2::AssociateClients, local_params)
      end
    end
  end
end
