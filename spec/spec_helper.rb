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
  config.include ProjectHelper
  config.include SchemaHelper

  config.before(:all) do
    # TODO: Fully setup global environment
    GoodData.logging_off

    pp GoodData.version

    GoodData.connect ENV['GD_GEM_USER'], ENV['GD_GEM_PASSWORD']

    domain = GoodData::Domain['gooddata-tomas-korcak']
    users = domain.users

    user = users[0]
    user.first_name = 'Tom'
    user.save!

    # domain = GoodData::Domain['gooddata-tomas-korcak']
    # domain.add_user(:login => 'korczis87@gmail.com', :password => 'ThisIsTheAir', :company => 'picoparnik', :authentication_modes => ['PASSWORD'])

    data = {
      :first_name => 'tomas'
    }
    user1 = GoodData::AccountSettings.create data
    user1.first_name = 'tomas'
    user1.last_name = 'korcak'
    user1.email = 'oh.my.tomas@gmail.com'

    data = {
      :first_name => 'tomas'
    }
    user2 = GoodData::AccountSettings.create data

    # d = GoodData::User.diff(user1, user2)

    projects = GoodData::Project.all
    project = projects[0]
    tmp = project.created
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
