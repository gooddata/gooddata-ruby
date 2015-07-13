# encoding: UTF-8

require 'rubygems'

require 'bundler/setup'
require 'bundler/gem_tasks'

# require 'coveralls/rake/task'

require 'rake/testtask'
require 'rake/notes/rake_task'
require 'rspec/core/rake_task'

require 'yard'

desc "Run Rubocop"
task :cop do
  exec "rubocop lib/"
end

# Coveralls::RakeTask.new

desc 'Run continuous integration test'
task :ci do
  Rake::Task['test:unit'].invoke
  unless ENV['TRAVIS'] == 'true' && ENV['TRAVIS_SECURE_ENV_VARS'] == 'false'
    Rake::Task['test:integration'].invoke
  end
  Rake::Task['test:cop'].invoke if RUBY_VERSION.start_with?('2.2') == false
  # Rake::Task['coveralls:push'].invoke
end

namespace :gem do
  desc "Release gem version #{GoodData::VERSION} to rubygems"
  task :release do |t|
    gem = "gooddata-#{GoodData::VERSION}.gem"

    puts "Building #{gem} ..."
    res = system('gem build ./gooddata.gemspec')
    next if !res

    puts "Pushing #{gem} ..."
    res = system("gem push #{gem}")
  end
end

namespace :hook do
  hook_path = File.join(File.dirname(__FILE__), '.git', 'hooks', 'pre-commit').to_s

  desc 'Installs git pre-commit hook running rubocop'
  task :install do |t|
    if(File.exist?(hook_path))
      puts 'Git pre-commit hook is already installed'
    else
      File.open(hook_path, 'w') do |file|
        file.write("#! /usr/bin/env bash\n")
        file.write("\n")
        file.write("rake cop\n")
      end
      system "chmod 755 #{hook_path}"
      puts 'Git commit hook was installed'
    end
  end

  desc 'Uninstalls git pre-commit hook'
  task :uninstall do |t|
    res = File.exist?(hook_path)
    if res
      puts 'Uninstalling git pre-commit hook'
      system "rm #{hook_path}"
      puts 'Git pre-commit hook was uninstalled'
    else
      puts 'Git pre-commit hook is not installed'
    end
  end

  desc 'Checks if is git pre-commit hook installed'
  task :check do
    res = File.exist?(hook_path)
    if res
      puts 'Git pre-commit IS installed'
    else
      puts 'Git pre-commit IS NOT installed'
    end
  end

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

  desc "Run legacy tests"
  RSpec::Core::RakeTask.new(:legacy) do |t|
    t.pattern = 'test/**/test_*.rb'
  end

  desc "Run coding style tests"
  RSpec::Core::RakeTask.new(:cop) do |t|
    Rake::Task['cop'].invoke
  end

  task :all => [:unit, :integration, :cop]
end

desc "Run all tests"
task :test => 'test:all'

task :usage do
  puts "No rake task specified, use rake -T to list them"
end

YARD::Rake::YardocTask.new

task :default => [:usage]
