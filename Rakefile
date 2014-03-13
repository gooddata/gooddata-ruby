require 'rubygems'

require 'bundler/setup'
require 'bundler/gem_tasks'

require 'rake/testtask'
require 'rspec/core/rake_task'

require 'yard'

RSpec::Core::RakeTask.new(:spec)

task :usage do
  puts "No rake task specified, use rake -T to list them"
end

namespace :test do
  RSpec::Core::RakeTask.new(:unit) do |t|
    t.pattern = 'spec/unit/**/*.rb'
  end

  RSpec::Core::RakeTask.new(:integration) do |t|
    t.pattern = 'spec/integration/**/*.rb'
  end

  # Rake::TestTask.new(:legacy) do |test|
  #   test.libs << 'lib' << 'test'
  #   test.pattern = 'test/**/test_*.rb'
  #   test.verbose = true
  # end
end

YARD::Rake::YardocTask.new

task :default => [:usage]