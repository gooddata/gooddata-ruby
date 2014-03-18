require 'rubygems'

require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rake/testtask'
require 'rspec/core/rake_task'

require 'yard'

desc "Run Rubocop"
task :cop do
  exec "rubocop"
end

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

  # Rake::TestTask.new(:legacy) do |test|
  #   test.libs << 'lib' << 'test'
  #   test.pattern = 'test/**/test_*.rb'
  #   test.verbose = true
  # end

  task :all => [:unit, :integration]
end

desc "Run all tests"
task :test => 'test:all'

task :usage do
  puts "No rake task specified, use rake -T to list them"
end

YARD::Rake::YardocTask.new

task :default => [:usage]