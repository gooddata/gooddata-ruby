module GoodData

  # Prerequisites:
  #
  # ENV["GD_SERVER_URL"] - e.g. 'https://secure.gooddata.com'
  # ENV["GD_USERNAME"] - e.g. 'bear@gooddata.com'
  # ENV["GD_PASSWORD"] - e.g. 'jindrisska'
  # ENV["GD_PROJECT_TOKEN"] - e.g. 'pgroup2'
  class IntegrationTestsRunner

    class << self
      private

      TESTS_LOCATION = '/spec/integration/'

      def initialize
        require 'tempfile'
        require 'json'
        require 'time'
        require 'builder'
        require 'rspec'
        require_relative 'spec/spec_helper'
      end


      public

      def run_integration_test(testname = :all)
        initialize

        if (testname == :all)
          specs = File.expand_path(File.dirname(__FILE__)) + TESTS_LOCATION
        else
          specs = File.expand_path(File.dirname(__FILE__)) + TESTS_LOCATION + testname + ".rb"
        end

        config = RSpec::configuration
        formatter = RSpec::Core::Formatters::DocumentationFormatter.new(config.output_stream)
        junit_formatter = JUnitFormatter.new
        reporter = RSpec::Core::Reporter.new(formatter, junit_formatter)
        config.instance_variable_set(:@reporter, reporter)

        RSpec::Core::Runner.run([specs])
        junit_formatter.result_str
      end
    end
  end
end