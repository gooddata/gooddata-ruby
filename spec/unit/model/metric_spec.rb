require 'gooddata/client'
require 'gooddata/models/metadata/metric'

describe GoodData::Metric do
  before(:all) do
    ConnectionHelper.create_default_connection
  end

  after(:all) do
    GoodData.disconnect
  end

  describe '#[]' do
    before(:all) do
      GoodData.project = nil
    end

    it 'Raises RuntimeError when no project selected' do
      expect { GoodData::Metric[:all] }.to raise_error(RuntimeError)
    end
  end
end