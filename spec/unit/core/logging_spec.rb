# encoding: UTF-8

require 'gooddata/core/logging'

describe 'GoodData - logging' do
  TEST_MESSAGE = 'Hello World!'

  def test_error
    GoodData.logger.error TEST_MESSAGE
  end

  def test_info
    GoodData.logger.info TEST_MESSAGE
  end

  def test_warn
    GoodData.logger.warn TEST_MESSAGE
  end

  def test_all
    test_error
    test_info
    test_info
  end

  before(:each) do
    @is_logging_on = GoodData.logging_on?

    # TODO: Use some kind of 'reset' instead
    GoodData.logging_on if !@is_logging_on
  end

  after(:each) do
    GoodData.logging_off if !@is_logging_on
  end


  describe '#logging_on' do
    it 'Enables logging' do
      GoodData.logging_on
      test_all
    end
  end

  describe '#logging_off' do
    it 'Disables logging' do
      GoodData.logging_off
      test_all
    end
  end

  describe '#logger' do
    it '#error works' do
      test_error
    end

    it '#info works' do
      test_info
    end

    it '#warn works' do
      test_warn
    end
  end
end