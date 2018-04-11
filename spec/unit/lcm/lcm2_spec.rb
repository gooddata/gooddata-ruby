# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

shared_examples 'a smart hash' do
  let(:expected_value) { 'bar' }
  it 'fetches value' do
    expect(subject.FOO).to eq(expected_value)
    expect(subject.foo).to eq(expected_value)
    expect(subject['FOO']).to eq(expected_value)
    expect(subject['foo']).to eq(expected_value)
    expect(subject[:FOO]).to eq(expected_value)
    expect(subject[:foo]).to eq(expected_value)
  end
end

describe 'GoodData::LCM2' do
  describe '#skip_actions' do
    let(:client) { double(:client) }
    let(:domain) { 'domain' }
    let(:logger) { GoodData.logger }
    let(:params) do
      params = {
        skip_actions: %w(CollectSegments SynchronizeUsers),
        GDC_GD_CLIENT: client,
        GDC_LOGGER: logger,
        domain: domain
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

  describe '#convert_to_smart_hash' do
    subject do
      GoodData::LCM2.convert_to_smart_hash(hash)
    end

    let(:hash) { { fooBarBaz: 'qUx' } }

    it 'keeps letter case' do
      expect(subject.to_h).to eq(hash)
    end

    context 'when hash contains symbol key in lower-case' do
      it_behaves_like 'a smart hash' do
        let(:hash) { { foo: 'bar' } }
      end
    end

    context 'when hash contains string key in lower-case' do
      it_behaves_like 'a smart hash' do
        let(:hash) { { 'foo' => 'bar' } }
      end
    end

    context 'when hash contains symbol key in upper-case' do
      it_behaves_like 'a smart hash' do
        let(:hash) { { FOO: 'bar' } }
      end
    end

    context 'when hash contains string key in upper-case' do
      it_behaves_like 'a smart hash' do
        let(:hash) { { 'FOO' => 'bar' } }
      end
    end
  end
end
