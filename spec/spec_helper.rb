# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'simplecov'
require 'pmap'
require 'rspec'
require 'pathname'
require 'webmock/rspec'

WebMock.disable!

# Automagically include all helpers/*_helper.rb

require_relative 'environment/environment'

GoodData::Environment.load

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + 'helpers/*_helper.rb').each do |file|
  require file
end

include GoodData::Helpers

RSpec::Expectations.configuration.warn_about_potential_false_positives = false

RSpec.configure do |config|
  config.deprecation_stream = File.open('deprecations.txt', 'w')

  config.include BlueprintHelper
  config.include CliHelper
  config.include ConnectionHelper
  config.include CryptoHelper
  config.include CsvHelper
  config.include ProcessHelper
  config.include ProjectHelper
  config.include ScheduleHelper
  # config.include SchemaHelper

  config.filter_run_excluding :broken => true

  config.fail_fast = false

  config.before(:all) do
    # TODO: Move this to some method.
    # TODO Make more intelligent so two test suites can run at the same time.
    # ConnectionHelper.create_default_connection
    # users = GoodData::Domain.users(ConnectionHelper::DEFAULT_DOMAIN)
    # users.pmap do |user|
    #   user.delete if user.email != ConnectionHelper::DEFAULT_USERNAME
    # end

    # TODO: Fully setup global environment
    # $stdout.sync=true
    # $stderr.sync=true

    GoodData.logging_off
    GoodData.stats_off
  end

  config.after(:all) do
    # TODO: Fully setup global environment
  end

  config.before(:suite) do
    # TODO: Setup test project
    GoodData.logging_off
  end

  config.after(:suite) do
    # TODO: Delete test project
  end
end

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter[
  SimpleCov::Formatter::HTMLFormatter
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
