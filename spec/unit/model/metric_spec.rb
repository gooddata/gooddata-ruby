require 'gooddata/client'
require 'gooddata/models/metric'

describe GoodData::Metric do
  before(:all) do
    ConnectionHelper.create_default_connection
  end

  after(:all) do
    GoodData.disconnect
  end

  describe '#[]' do
    it 'Raises RuntimeError when no project selected' do
      expect { GoodData::Metric[:all] }.to raise_error(RuntimeError)
    end
  end
end