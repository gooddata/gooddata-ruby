# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

describe 'GoodData::LCM2' do
  describe '#skip_actions' do
    let(:client) { double(:client) }
    let(:domain) { double(:domain) }
    let(:logger) { double(:logger) }
    let(:params) do
      params = {
        skip_actions: ['CollectSegments', 'SynchronizeUsers'],
        GDC_GD_CLIENT: client,
        GDC_LOGGER: logger
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(client).to receive(:class) { GoodData::Rest::Client }
      allow(client).to receive(:domain) { domain }
      allow(logger).to receive(:info)
      allow(domain).to receive(:data_products)
    end

    it 'skips actions in skip_actions' do
      expect(GoodData::LCM2::CollectSegments).not_to receive(:call)
      expect(GoodData::LCM2::SynchronizeUsers).not_to receive(:call)
      GoodData::LCM2.perform('users', params)
    end
  end
end
