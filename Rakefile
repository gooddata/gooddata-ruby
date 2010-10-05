require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "GoodData Ruby wrapper and CLI"
    gem.summary = %Q{A convenient Ruby wrapper around the GoodData RESTful API}
    gem.description = %Q{This is a two-in one tool. It both contains a wrapper class called GoodData::Base that you can use in your own projects and a CLI for use on the prompt.}
    gem.email = "w@tson.dk"
    gem.homepage = "http://github.com/gooddata/gooddata-ruby"
    gem.authors = ["Thomas Watson Steen"]
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_dependency 'parseconfig'
    gem.add_dependency 'json'
    gem.add_dependency 'rest-client'
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :test => :check_dependencies

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "gooddata-ruby #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
