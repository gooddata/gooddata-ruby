require 'rubygems'
require 'rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "gooddata"
    gem.summary = %Q{A convenient Ruby wrapper around the GoodData RESTful API}
    gem.description = %Q{Use the Gooddata::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.}
    gem.email = "w@tson.dk"
    gem.homepage = "http://github.com/gooddata/gooddata-ruby"
    gem.authors = ["Thomas Watson Steen"]
    gem.files = Dir["**/*"].select { |d| d =~ %r{^(README|LICENSE|VERSION|bin/|data/|ext/|lib/|spec/|test/)} }
    gem.add_development_dependency "thoughtbot-shoulda", ">= 0"
    gem.add_dependency 'parseconfig'
    gem.add_dependency 'json_pure'
    gem.add_dependency 'rest-client'
    gem.add_dependency 'fastercsv'
    gem.add_dependency 'json'
    gem.add_dependency 'rubyzip'
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
