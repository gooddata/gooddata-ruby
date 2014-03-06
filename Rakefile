require 'rubygems'
require 'bundler/setup'

require 'bundler/gem_tasks'
require 'rake/testtask'

RSpec::Core::RakeTask.new(:spec)

task :usage do
  puts "No rake task specified, use rake -T to list them"
end

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => [:usage]