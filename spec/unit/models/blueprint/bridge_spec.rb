# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Model::BridgeBlueprintField do
  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/nu_model.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.parentplanbookings')
    @attribute = @dataset.attributes('attr.opportunityanalysis.month')
  end

  describe '#dataset' do
    it 'should return dataset' do
      expect(@dataset.bridges.first.dataset.id).to eq 'dataset.oracleebsreports'
    end
  end
end
