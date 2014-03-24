require 'rubygems'

require 'bundler/setup'
require 'bundler/gem_tasks'

require 'coveralls/rake/task'

require 'rake/testtask'
require 'rspec/core/rake_task'

require 'yard'

desc "Run Rubocop"
task :cop do
  exec "rubocop lib/"
end

Coveralls::RakeTask.new

desc "Create rspec coverage"
task :coverage do
  ENV['COVERAGE'] = 'true'
  Rake::Task["test:unit"].execute
end

desc 'Run tests with coveralls'
task :coveralls => ['coverage', 'coveralls:push']

RSpec::Core::RakeTask.new(:test)

namespace :test do
  desc "Run unit tests"
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*.rb'
  end

  desc "Run integration tests"
  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*.rb'
  end

  desc "Run legacy tests"
  RSpec::Core::RakeTask.new(:legacy) do |t|
    t.pattern = 'test/**/test_*.rb'
  end

  task :all => [:unit, :integration]
end

desc "Run all tests"
task :test => 'test:all'

task :usage do
  puts "No rake task specified, use rake -T to list them"
end

YARD::Rake::YardocTask.new

task :default => [:usage]