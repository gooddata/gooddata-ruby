describe GoodData::Model::DatasetBlueprint do
  let(:dataset) do
    { columns: [{ type: 'hll' },
                { type: 'fact' },
                { type: 'date_fact' }] }
  end
  subject { GoodData::Model::DatasetBlueprint }
  describe '.facts' do
    it 'returns facts of supported types' do
      result = subject.facts(dataset)
      expect(result).to eq(dataset[:columns])
    end
  end
end
