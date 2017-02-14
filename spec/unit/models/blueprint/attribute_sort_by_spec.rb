# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Model::AttributeBlueprintField do
  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/attribute_sort_by_model.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.id')
    @attribute = @dataset.attributes('attr.id.name')
  end

  it 'should return label id and direction of sorted attribute' do
    expect(@attribute.order_by).to eq 'label.id.name.name_label_2 - DESC'
  end
end
