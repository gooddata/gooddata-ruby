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

RSpec::Core::RakeTask.new(:unit) do |t|
  t.warning = true
  t.rcov = true
  t.ruby_opts = ['-r spec/unit']
end

RSpec::Core::RakeTask.new(:integration) do |t|
  t.warning = true
  t.rcov = true
  t.ruby_opts = ['-r spec/integration']

end

Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

YARD::Rake::YardocTask.new

task :default => [:usage]