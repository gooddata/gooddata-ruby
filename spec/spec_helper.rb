# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
#
ENV['RSPEC_ENV'] = 'test'

require 'simplecov'
# for simplecov to work correctly, it has to be started before any other code
SimpleCov.start do
  add_filter 'spec/'

  add_group 'Middleware', 'lib/gooddata/bricks/middleware'
  add_group 'CLI', 'lib/gooddata/cli'
  add_group 'Commands', 'lib/gooddata/commands'
  add_group 'Core', 'lib/gooddata/core'
  add_group 'Exceptions', 'lib/gooddata/exceptions'
  add_group 'Extensions', 'lib/gooddata/extensions'
  add_group 'Goodzilla', 'lib/gooddata/goodzilla'
  add_group 'Models', 'lib/gooddata/models'
  add_group 'LCM', 'lib/gooddata/lcm'
end

require 'pmap'
require 'rspec'
require 'pathname'
require 'webmock/rspec'
require 'gooddata'

vcr_enabled = !ENV['VCR_ON'] || ENV['VCR_ON'] == 'true' # VCR is enabled by default - set VCR_ON=false to disable
require 'vcr_configurer' if vcr_enabled

logger = Logger.new(STDOUT)
logger.level = Logger::WARN
GoodData.logger = logger

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

  if vcr_enabled
    config.before(:all) do
      # in case the test uses VCR
      if self.class.metadata[:vcr]
        # replace parallel iterations with the serial one, since VCR can't handle parallel request matching correctly
        module Enumerable
          def peach_with_index(*, &y)
            each_with_index(&y)
          end
        end

        # insert the cassete recording everything what happens outside the tests cases
        VCR.insert_cassette("#{self.class.metadata[:description]}/all")
      end
    end

    config.after(:all) do
      # in case the test uses VCR
      if self.class.metadata[:vcr]
        # eject the cassete recording everything what happens outside the tests cases
        VCR.eject_cassette

        # reload the original parallel iterations
        load('pmap.rb') if self.class.metadata[:vcr]
      end
    end
  end
end
