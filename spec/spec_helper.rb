# encoding: UTF-8

require 'simplecov'
require 'pmap'
require 'rspec'
require 'coveralls'
require 'pathname'
require 'rspec/core/formatters/base_formatter'


Coveralls.wear_merged!

# Automagically include all helpers/*_helper.rb

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + 'helpers/*_helper.rb').each do |file|
  require file
end

RSpec.configure do |config|
  config.include BlueprintHelper
  config.include CliHelper
  config.include ConnectionHelper
  config.include CryptoHelper
  config.include CsvHelper
  config.include ProcessHelper
  config.include ProjectHelper
  # config.include SchemaHelper

  config.filter_run_excluding :broken => true

  config.before(:all) do
    # TODO: Move this to some method.
    # TODO Make more intelligent so two test suites can run at the same time.
    # ConnectionHelper.create_default_connection
    # users = GoodData::Domain.users(ConnectionHelper::DEFAULT_DOMAIN)
    # users.pmap do |user|
    #   user.delete if user.email != ConnectionHelper::DEFAULT_USERNAME
    # end

    # TODO: Fully setup global environment
    GoodData.logging_off
  end

  config.after(:all) do
    # TODO: Fully setup global environment
  end

  config.before(:suite) do
    # TODO: Setup test project
  end

  config.after(:suite) do
    # TODO: Delete test project
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter
]

SimpleCov.start do
  add_filter 'spec/'
  add_filter 'test/'

  add_group 'Bricks', 'lib/gooddata/bricks'
  add_group 'Middleware', 'lib/gooddata/bricks/middleware'
  add_group 'CLI', 'lib/gooddata/cli'
  add_group 'Commands', 'lib/gooddata/commands'
  add_group 'Core', 'lib/gooddata/core'
  add_group 'Exceptions', 'lib/gooddata/exceptions'
  add_group 'Extensions', 'lib/gooddata/extensions'
  add_group 'Goodzilla', 'lib/gooddata/goodzilla'
  add_group 'Models', 'lib/gooddata/models'
end



class JUnitFormatter < RSpec::Core::Formatters::BaseFormatter

  attr_accessor :result_str

  def initialize

    super StringIO.new
    @test_results = []
    @result_str = ''
  end

  def example_passed example
    @test_results << example
  end

  def example_failed example
    @test_results << example
  end

  def example_pending example
    @test_results << example
  end

  def failure_details_for example
    exception = example.metadata[:execution_result][:exception]
    exception.nil? ? "" : "#{exception.message}\n#{format_backtrace(exception.backtrace, example).join("\n")}"
  end

  def full_name_for example
    test_name = ""
    current_example_group = example.metadata[:example_group]
    until current_example_group.nil? do
      test_name = "#{current_example_group[:description]}." + test_name
      current_example_group = current_example_group[:example_group]
    end
    test_name << example.metadata[:description]
  end

  def dump_summary duration, example_count, failure_count, pending_count
    builder = Builder::XmlMarkup.new :indent => 2
    builder.instruct! :xml, :version => "1.0", :encoding => "UTF-8"
    builder.testsuite :errors => 0, :failures => failure_count, :skipped => pending_count, :tests => example_count, :time => duration, :timestamp => Time.now.iso8601 do
      builder.properties
      @test_results.each do |test|
        builder.testcase :classname => full_name_for(test), :name => test.metadata[:full_description], :time => test.metadata[:execution_result][:run_time] do
          case test.metadata[:execution_result][:status]
            when "failed"
              builder.failure :message => "failed #{test.metadata[:full_description]}", :type => "failed" do
                builder.cdata! failure_details_for test
              end
            when "pending" then builder.skipped
          end
        end
      end
    end
    @result_str = builder.target!
  end
end