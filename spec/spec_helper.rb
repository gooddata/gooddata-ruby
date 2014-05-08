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

def delete_old_projects
  projects = GoodData::Project.all
  projects.each do |project|
    # TODO: Delete only projects which were updated more than hour ago
    if project.title.include? ProjectHelper::TEST_PROJECT_NAME
      puts "Deleting #{project.title}"
      project.delete
    end
  end
end


RSpec.configure do |config|
  config.include BlueprintHelper
  config.include CliHelper
  config.include ConnectionHelper
  config.include ProjectHelper
  config.include SchemaHelper

  config.before(:all) do
    # TODO: Fully setup global environment
    GoodData.logging_off

    # Delete old stuff
    ConnectionHelper.create_default_connection
    delete_old_projects
    GoodData.disconnect
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
