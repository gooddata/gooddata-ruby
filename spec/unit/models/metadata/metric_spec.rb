# encoding: UTF-8

require 'gooddata'

describe GoodData::Metric, :metric => true do
  before(:each) do
    ConnectionHelper::create_default_connection
    @metric = MetricHelper.default_metric
  end

  after(:each) do
    GoodData.disconnect
  end

  describe '#author' do
    it 'Returns author as GoodData::Profile' do
      res = @metric.author
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#contributor' do
    it 'Returns contributor as GoodData::Profile' do
      res = @metric.contributor
      expect(res).to be_instance_of(GoodData::Profile)
    end
  end

  describe '#created' do
    it 'Returns date when created as Time' do
      res = @metric.created
      expect(res).to be_instance_of(Time)
    end
  end

  describe '#title' do
    it 'Returns title as String' do
      res = @metric.title
      expect(res).to be_instance_of(String)
    end
  end

  describe '#updated' do
    it 'Returns date when created as Time' do
      res = @metric.created
      expect(res).to be_instance_of(Time)
    end
  end
end