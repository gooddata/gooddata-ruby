# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Model::AttributeBlueprintField do

  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.account')
    @attribute = @dataset.attributes('attr.account.region')
  end

  describe '#labels' do
    it 'should return labels on dataset' do
      expect(@attribute.labels.count).to eq 1
    end
  end

  describe '#dataset' do
    it 'should return dataset of the attribtue field' do
      expect(@attribute.dataset_blueprint).to eq @dataset
    end
  end
end
