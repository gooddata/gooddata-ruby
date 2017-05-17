# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_meta'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::CollectMeta do
  let(:development_client) { double('development_client') }
  let(:dashboard) { double('dashboard', uri: 'tagged/dashboard/uri') }

  before do
    allow(development_client).to receive(:projects).and_return({})
  end

  context 'when no production tag configured' do
    let(:params) do
      params = {
        development_client: development_client,
        synchronize: [{ from: 'project_id' }]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'retrieves all dashboards' do
      expect(GoodData::Dashboard).to receive(:all).and_return({})
      subject.class.call(params)
    end
  end

  context 'when global production tag configured' do
    let(:params) do
      params = {
        development_client: development_client,
        synchronize: [{ from: 'project_id' }],
        production_tag: 'production_tag'
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'retrieves dashboards by the specified tag' do
      expect(GoodData::Dashboard).to receive(:find_by_tag)
        .with(['production_tag'], any_args)
        .and_return({})
      subject.class.call(params)
    end
  end

  context 'when segment-specific production tag configured' do
    let(:params) do
      params = {
        development_client: development_client,
        synchronize: [{ from: 'project_id' }],
        segments: [{ production_tag: 'segment_production_tag' }, {}]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'retrieves dashboards by the specified tag' do
      expect(GoodData::Dashboard).to receive(:find_by_tag)
        .with(['segment_production_tag'], any_args)
        .and_return({})
      subject.class.call(params)
    end
  end

  context 'when both global and segment-specific production tags configured' do
    let(:params) do
      params = {
        development_client: development_client,
        synchronize: [{ from: 'project_id' }],
        segments: [{ production_tag: 'segment_production_tag' }, {}],
        production_tag: 'production_tag'
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'preffers segment-specific tags' do
      expect(GoodData::Dashboard).to receive(:find_by_tag)
        .with(%w(segment_production_tag), any_args)
        .and_return({})
      subject.class.call(params)
    end
  end
end
