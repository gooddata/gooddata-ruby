# encoding: UTF-8
require 'gooddata'

describe GoodData::Model::ReferenceBlueprintField do

  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.opportunityanalysis')
    @attribute = @dataset.attributes('attr.opportunityanalysis.month')
  end

  describe '#dataset' do
    it 'should return labels on dataset' do
      expect(@dataset.references.first.dataset.id).to eq 'dataset.opp_records'
    end
  end

  describe '#reference' do
    it 'should return reference on dataset' do
      expect(@dataset.references.first.reference).to eq 'dataset.opp_records'
    end
  end
end
