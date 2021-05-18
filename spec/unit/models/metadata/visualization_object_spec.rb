# encoding: UTF-8
# frozen_string_literal: true
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

VISUALIZATION_OBJECT_RAW_DATA = {
    'visualizationObject' => {
        'content' => {
            'buckets' => [],
            'properties' => '',
            'visualizationClass' => {}
        },
        'meta' => {
            'author' => '/gdc/account/profile/4e1e8cac228e0ae531b30853248',
            'uri' => '/gdc/md/w2bbq79qeuqzjhwm9xln0865v7yb/obj/70',
            'tags' => '',
            'created' => '2021-04-22 10:23:24',
            'identifier' => 'aabszNAtXFsJ',
            'deprecated' => '0',
            'summary' => 'Summary Testing',
            'title' => 'Dashboard Testing',
            'category' => 'visualizationObject',
            'updated' => '2021-04-23 13:03:48',
            'contributor' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248'
        }
    }
}

describe GoodData::VisualizationObject do
  before do
    @instance = GoodData::VisualizationObject.new(GoodData::Helpers.deep_dup(VISUALIZATION_OBJECT_RAW_DATA))
  end

  describe '#title' do
    it 'title' do
      expect(@instance.title).to eq('Dashboard Testing')
    end
    it 'set title' do
      @instance.title = 'New title'
      expect(@instance.title).to eq('New title')
    end
  end

  describe '#summary' do
    it 'summary' do
      expect(@instance.summary).to eq('Summary Testing')
    end
    it 'set summary' do
      @instance.summary = 'New summary'
      expect(@instance.summary).to eq('New summary')
    end
  end

  describe '#deprecated' do
    it 'returns true/false' do
      expect(@instance.deprecated).to be_falsey
    end
    it 'set deprecated flag' do
      expect(@instance.deprecated).to be_falsey
      @instance.deprecated = true
      expect(@instance.deprecated).to be_truthy
    end
  end
end
