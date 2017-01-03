# encoding: utf-8
$LOAD_PATH.push File.expand_path('../lib/', __FILE__)
require 'gooddata/version'

Gem::Specification.new do |s|
  s.name = 'gooddata'
  s.version = GoodData::VERSION
  s.licenses = ['BSD']

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = [
    'Pavel Kolesnikov',
    'Thomas Watson Steen',
    'Tomas Svarovsky',
    'Tomas Korcak'
  ]

  s.summary = 'A convenient Ruby wrapper around the GoodData RESTful API'
  s.description = 'Use the GoodData::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.'
  s.email = 'pavel@gooddata.com'
  s.extra_rdoc_files = %w(LICENSE README.md)

  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.homepage = 'http://github.com/gooddata/gooddata-ruby'
  s.require_paths = ['lib']

  s.add_development_dependency 'bundler', "~> 1.13.0"
  s.add_development_dependency 'debase', '~> 0.1.0' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'
  s.add_development_dependency 'license_finder', '~> 2.0.0'
  s.add_development_dependency 'rake', '~> 11.1.0'
  s.add_development_dependency 'rake-notes', '~> 0.2.0'
  s.add_development_dependency 'redcarpet', '~> 3.1.0' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  s.add_development_dependency 'rspec-expectations', '~> 3.5.0'
  s.add_development_dependency 'rubocop', '~> 0.45.0'
  s.add_development_dependency 'ruby-debug-ide', '~> 0.4' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'
  s.add_development_dependency 'simplecov', '~> 0.12.0'
  s.add_development_dependency 'webmock', '~> 1.21.0'
  s.add_development_dependency 'yard', '~> 0.8.7.6'
  s.add_development_dependency 'yard-rspec', '~> 0.1'
  s.add_development_dependency 'ZenTest', '~> 4.11.0'

  s.add_dependency 'nokogiri', '~> 1.6.8'
  s.add_dependency 'aws-sdk-v1', '~> 1.45'
  s.add_dependency 'docile', '~> 1.1.0'
  s.add_dependency 'erubis', '~> 2.7.0'
  s.add_dependency 'gli', '~> 2.13.0'
  s.add_dependency 'highline', '~> 1.7.0'
  s.add_dependency 'json_pure', '~> 1.8.0'
  s.add_dependency 'multi_json', '~> 1.11.0'
  s.add_dependency 'parseconfig', '~> 1.0.0'
  s.add_dependency 'pmap', '~> 1.0.0'
  s.add_dependency 'restforce', '~> 2.4.0'
  s.add_dependency 'rest-client', '~> 1.8.0'
  s.add_dependency 'rubyzip', '~> 1.1.0'
  s.add_dependency 'salesforce_bulk_query', '~> 0.2.0'
  s.add_dependency 'terminal-table', '~> 1.5.0'
  s.add_dependency 'thread_safe'
end
