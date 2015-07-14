# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib/", __FILE__)
require 'gooddata/version'

Gem::Specification.new do |s|
  s.name = %q{gooddata}
  s.version = GoodData::VERSION
  s.licenses = ['BSD']

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = [
      'Pavel Kolesnikov',
      'Thomas Watson Steen',
      'Tomas Svarovsky',
      'Tomas Korcak'
  ]

  s.summary = %q{A convenient Ruby wrapper around the GoodData RESTful API}
  s.description = %q{Use the GoodData::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.}
  s.email = %q{pavel@gooddata.com}
  s.extra_rdoc_files = %w(LICENSE README.md)

  s.files = `git ls-files`.split($/)
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.homepage = %q{http://github.com/gooddata/gooddata-ruby}
  s.require_paths = ["lib"]

  s.add_development_dependency 'rake', '~> 10.3', '>= 10.3.1'
  s.add_development_dependency 'rake-notes', '~> 0.2', '>= 0.2.0'
  s.add_development_dependency 'redcarpet', '~> 3.1', '>= 3.1.1' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'rspec', '~> 2.14', '>= 2.14.1'
  s.add_development_dependency 'rubocop', '~> 0.32.1', '>= 0.32.1'
  s.add_development_dependency 'simplecov', '~> 0.9', '>= 0.9.1'
  s.add_development_dependency 'yard', '~> 0.8.7.3'
  s.add_development_dependency 'yard-rspec', '~> 0.1'
  s.add_development_dependency 'ZenTest', '~> 4.10', '>= 4.11.0'
  s.add_development_dependency 'coveralls', '~> 0.7', '>= 0.7.0'
  s.add_development_dependency 'guard', '~> 2'
  s.add_development_dependency 'guard-rspec', '~> 4'
  s.add_development_dependency 'webmock', '~> 1.21', '>= 1.21.0'
  s.add_development_dependency 'debase', '~> 0.1', '>= 0.1.7' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'
  s.add_development_dependency 'ruby-debug-ide', '~> 0.4' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'

  s.add_dependency 'activesupport', '~> 4.1', '>= 4.1.0'
  s.add_dependency 'bundler', '~> 1.7', '>= 1.7.3'
  s.add_dependency 'docile', '~> 1.1', '>= 1.1.5'
  s.add_dependency 'erubis', '~> 2.7', '>= 2.7.0'
  s.add_dependency 'gli', '~> 2.12', '>= 2.12.2'
  s.add_dependency 'highline', '~> 1.6', '>= 1.6.21'
  s.add_dependency 'i18n', '~> 0.6', '>= 0.6.9'
  s.add_dependency 'json_pure', '~> 1.8', '>= 1.8.1'
  s.add_dependency 'multi_json', '~> 1.10', '>= 1.10.0'
  s.add_dependency 'parseconfig', '~> 1.0', '>= 1.0.4'
  s.add_dependency 'pmap', '~> 1.0', '>= 1.0.1'
  s.add_dependency 'pry', '~> 0.9.12.6' # '~> 0.10', '>= 0.10.1'
  s.add_dependency 'restforce', '~> 1.5', '>= 1.5.0'
  s.add_dependency 'rest-client', '~> 1.7.2', '>= 1.7.2'
  s.add_dependency 'rubyzip', '~> 1.1', '>= 1.1.0'
  s.add_dependency 'terminal-table', '~> 1.5', '>= 1.5.1'
  s.add_dependency 'salesforce_bulk_query', '~> 0.0'
  s.add_dependency 'aws-sdk', '~> 1.45'
end
