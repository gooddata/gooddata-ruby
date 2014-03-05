require 'rspec/core/rake_task'

require "bundler/gem_tasks"
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end
