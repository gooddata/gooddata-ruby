# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Model::LabelBlueprintField do
  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.opportunityanalysis')
    @attribute = @dataset.attributes('attr.opportunityanalysis.month')
  end

  describe '#attribute' do
    it 'should return attribute on label' do
      labels = @attribute.labels
      expect(labels.count).to eq 2

      expect(labels[0].attribute).to eq @attribute
      expect(labels[1].attribute).to eq @attribute

      expect(labels[0].dataset_blueprint).to eq @dataset
      expect(labels[1].dataset_blueprint).to eq @dataset
    end
  end

  context 'reading the label' do
    before do
      @label = @blueprint.datasets('dataset.opportunityanalysis').labels('label.opportunityanalysis.techoppanalysis')
    end

    it 'should return attribute on label' do
      expect(@label.gd_type).to eq 'GDC.text'
    end

    it 'should return attribute on label' do
      expect(@label.gd_data_type).to eq 'VARCHAR(128)'
    end
  end
end
