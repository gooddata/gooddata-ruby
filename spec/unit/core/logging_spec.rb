# encoding: UTF-8

require 'gooddata/core/logging'
require 'logger'

# Logger that remembers the last logged message
class TestLogger < Logger
  attr_reader :last_message
  def debug(*args)
    @last_message = args[0] if level == Logger::DEBUG
    super(*args)
  end
  def info(*args)
    @last_message = args[0] if level == Logger::INFO
    super(*args)
  end
  def warn(*args)
    @last_message = args[0] if level == Logger::WARN
    super(*args)
  end
  def error(*args)
    @last_message = args[0] if level == Logger::ERROR
    super(*args)
  end
end



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

  def test_request_id_logging
    c = ConnectionHelper.create_default_connection
    id = c.generate_request_id
    GoodData.logger.info "Request id: #{id} Doing something very useful"
    c.get('/gdc/md', :request_id => id)
    id
  end

  def test_all
    test_error
    test_info
    test_warn
    test_request_id_logging
  end

  before(:each) do
    # remember the state of logging before
    @logging_on_at_start = GoodData.logging_on?
  end

  after(:each) do
    # restore the logging state
    if @logging_on_at_start
      GoodData.logging_on
    else
      GoodData.logging_off
    end
  end

  describe '#logger' do
    it "can assign a custom logger" do
      GoodData.logger = TestLogger.new(STDOUT)
      test_all
    end
    it 'has the request id logged when I passed it' do
      GoodData.logger = TestLogger.new(STDOUT)
      id = test_request_id_logging
      expect(GoodData.logger.last_message).to include(id)
    end
    it 'client logs when given custom message' do
      GoodData.logger = TestLogger.new(STDOUT)
      GoodData.logger.level = Logger::INFO
      c = ConnectionHelper.create_default_connection
      message = "Getting all projects."
      c.get('/gdc/md', :info_message => message)
      expect(GoodData.logger.last_message).to include(message)
    end
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