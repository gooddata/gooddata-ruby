# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/collect_tagged_objects'
require 'gooddata/lcm/lcm2'

shared_examples 'a tagged object collector' do
  it 'collects tagged objects' do
    result = subject.class.call(params)
    expected = {
      results: [{ project: 'some_development_project_id',
                  transfer_uri: 'tagged1' },
                { project: 'some_development_project_id',
                  transfer_uri: 'tagged2' }],
      params: {
        synchronize: [{
          from: 'some_development_project_id',
          transfer_uris: tagged_objects
        }]
      }
    }
    expect(result).to eq(expected)
  end

  it 'finds projects by the specified tags' do
    expect(development_project).to receive(:find_by_tag)
      .with(['production_tag'])
    subject.class.call(params)
  end
end

describe GoodData::LCM2::CollectTaggedObjects do
  let(:development_client) { double('development_client') }

  context 'when no production tags configured' do
    let(:params) do
      params = {
        development_client: development_client,
        synchronize: [{}],
        segments: [{}]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    before do
      allow(development_client).to receive(:projects).and_return({})
    end

    it 'returns an empty array' do
      result = subject.class.call(params)
      expect(result).to be_empty
    end
  end

  context 'when global production tags configured' do
    let(:tagged_objects) { %w(tagged1 tagged2) }
    let(:development_project) { double('development_project') }

    before do
      allow(development_project).to receive(:find_by_tag)
      .and_return(tagged_objects)
      allow(development_client).to receive(:projects)
      .and_return(development_project)
    end

    context 'when segment-specific production tags specified' do
      let(:params) do
        params = {
          development_client: development_client,
          synchronize: [{ from: 'some_development_project_id' }],
          segments: [{ production_tags: 'production_tag' }, {}]
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it_behaves_like 'a tagged object collector'
    end

    context 'when global production tags specified' do
      let(:params) do
        params = {
          development_client: development_client,
          synchronize: [{ from: 'some_development_project_id' }],
          segments: [{}],
          production_tags: 'production_tag'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it_behaves_like 'a tagged object collector'
    end

    context 'when both global and segment-specific production tags specified' do
      let(:params) do
        params = {
          development_client: development_client,
          synchronize: [{ from: 'some_development_project_id' }],
          segments: [{ production_tags: 'production_tag' }, {}],
          production_tags: 'global_production_tag'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it_behaves_like 'a tagged object collector'
    end

    context 'when using multi tags' do
      let(:params) do
        params = {
          development_client: development_client,
          synchronize: [{ from: 'some_development_project_id' }],
          segments: [{ production_tags: %w(production_tag prod_tag2) }, {}]
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'finds projects by the specified tags' do
        expect(development_project).to receive(:find_by_tag).with(%w(production_tag prod_tag2))
        subject.class.call(params)
      end
    end
  end
end
