# encoding: UTF-8
require 'gooddata'

describe GoodData::Model::DatasetBlueprint do

  before(:each) do
    @model_view = MultiJson.load(File.read('./spec/data/wire_models/model_view.json'))
    @blueprint = GoodData::Model::FromWire.from_wire(@model_view)
    @dataset = @blueprint.datasets('dataset.opportunityanalysis')
    @small_blueprint = GoodData::Model::ProjectBlueprint.build('my_bp') do |p|
      p.add_dataset('dataset.countries') do |d|
        d.add_anchor('attr.country')
        d.add_label('label.country.name', reference: 'attr.country')
      end
      p.add_dataset('dataset.repos') do |d|
        d.add_anchor('attr.repository')
        d.add_label('label.repo.name', reference: 'attr.repository')
        d.add_reference('dataset.countries')
      end
      p.add_dataset('dataset.devs') do |d|
        d.add_anchor('attr.dev')
        d.add_label('label.dev.name', reference: 'attr.dev')
      end
      p.add_dataset('dataset.commits') do |d|
        d.add_anchor('attr.commits')
        d.add_attribute('attr.quality')
        d.add_label('label.quality', reference: 'attr.quality')
        d.add_fact('more_numbers')
        d.add_reference('dataset.repos')
        d.add_reference('dataset.devs')
      end
    end
  end

  describe '#facts' do
    it 'should return facts on dataset' do
      expect(@dataset.facts.count).to eq 2
      expect(@dataset.facts.map(&:id).to_set).to eq [
        'fact.opportunityanalysis.buckets_to_display',
        'fact.opportunityanalysis.month_fact'
      ].to_set
    end

    it 'should be able to pick specific fact' do
      expect(@dataset.facts('fact.opportunityanalysis.buckets_to_display').id).to eq 'fact.opportunityanalysis.buckets_to_display'
    end
  end

  describe '#attributes' do
    it 'should return attributes on dataset' do
      expect(@dataset.attributes.count).to eq 2
      expect(@dataset.attributes.map(&:id).to_set).to eq [
        'attr.opportunityanalysis.month',
        'attr.opportunityanalysis.cohorttype'
      ].to_set
    end

    it 'should return attributes on dataset' do
      expect(@dataset.attributes('attr.opportunityanalysis.cohorttype').id).to eq 'attr.opportunityanalysis.cohorttype'
    end
  end

  describe '#labels' do
    it 'should return labels on dataset' do
      expect(@dataset.labels.count).to eq 4
      expect(@dataset.labels.map(&:id).to_set).to eq [
        'label.opportunityanalysis.month.monthsortingnew',
        'label.opportunityanalysis.month',
        'label.opportunityanalysis.cohorttype',
        'label.opportunityanalysis.techoppanalysis'
      ].to_set
    end
  end

  describe '#references' do
    it 'should return references on dataset' do
      expect(@dataset.references.count).to eq 2
      expect(@dataset.references.map {|r| r.data[:dataset]}).to eq [
        'dataset.opp_records',
        'dataset.consolidatedmarketingstatus'
      ]
    end
  end

  describe '#referenced_by' do
    it 'should return datasets that are referencing this one' do
      expect(@dataset.referenced_by).to eq []
      dimension = @blueprint.datasets('dataset.opp_records')
      expect(dimension.referenced_by.map(&:id)).to eq ['dataset.opportunityanalysis']
    end
  end

  describe '#referencing' do
    it 'should return datasets that are referenced by this one (the references in the dataset leads to those datasets)' do
      expect(@dataset.referencing.map(&:id)).to eq ['dataset.opp_records', 'dataset.consolidatedmarketingstatus']
      dimension = @blueprint.datasets('dataset.productline')
      expect(dimension.referencing.map(&:id)).to be_empty
      dimension = @blueprint.datasets('dataset.opp_records')
      expect(dimension.referencing.map(&:id).count).to eq 28
    end
  end

  describe '#breaks' do
    it 'should return attributes that the dataset can break' do
      expect(@small_blueprint.datasets('dataset.countries').breaks.map(&:id)).to eq ['attr.country', 'attr.repository', 'attr.quality']
      expect(@small_blueprint.datasets('dataset.devs').breaks.map(&:id)).to eq ['attr.dev', 'attr.quality']
    end
  end

  describe '#broken_by' do
    it 'should return attributes that the dataset can be broken by' do
      expect(@small_blueprint.datasets('dataset.commits').broken_by.map(&:id)).to eq ['attr.quality', 'attr.repository', 'attr.country', 'attr.dev']
      expect(@small_blueprint.datasets('dataset.devs').broken_by.map(&:id)).to eq ['attr.dev']
    end
  end
end
