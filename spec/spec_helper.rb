# encoding: UTF-8

require 'simplecov'
require 'rspec'
require 'coveralls'
require 'pathname'

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
  config.include CsvHelper
  config.include DashboardHelper
  config.include MetricHelper
  config.include ProjectHelper
  config.include ReportHelper
  config.include ReportDefinitionHelper
  config.include SchemaHelper

  config.filter_run_excluding :broken => true

  config.before(:all) do
    # TODO: Move this to some method.
    # TODO Make more intelligent so two test suites can run at the same time.

    ConnectionHelper.create_default_connection

    ProjectHelper.delete_all_projects

    # users = GoodData::Domain.users_map(ConnectionHelper::DEFAULT_DOMAIN)
    # users.each do |user|
    #   user.delete if user.email != ConnectionHelper::DEFAULT_USERNAME
    # end

    # ReportHelper.delete_all_reports

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
