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

  # s.add_development_dependency 'bundler', "~> 1.13", '>= 1.13.6'
  # s.add_development_dependency 'debase', '~> 0.1', '>= 0.1.7' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'
  s.add_development_dependency 'license_finder', '~> 2.0', '>= 2.0.4'
  s.add_development_dependency 'rake', '~> 13.0'
  s.add_development_dependency 'rake-notes', '~> 0.2', '>= 0.2.0'
  s.add_development_dependency 'redcarpet', '~> 3.1', '>= 3.1.1' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'rspec', '~> 3.12.0'
  s.add_development_dependency 'rspec-expectations', '~> 3.12'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.6.0'
  if RUBY_VERSION >= '2.6'
    s.add_development_dependency 'rubocop', '>= 1.28'
  else
    s.add_development_dependency 'rubocop', '~> 0.81'
  end

  # s.add_development_dependency 'ruby-debug-ide', '~> 0.4' if !ENV['TRAVIS_BUILD'] && RUBY_VERSION >= '2.0.0'
  s.add_development_dependency 'simplecov', '~> 0.12'
  s.add_development_dependency 'webmock', '~> 2.3.1'
  s.add_development_dependency 'yard', '~> 0.9.11'
  s.add_development_dependency 'yard-rspec', '~> 0.1'
  s.add_development_dependency 'ZenTest', '~> 4.10', '>= 4.11.0'

  if RUBY_VERSION >= '3.1'
    # net-smtp, net-imap and net-pop were removed from default gems in Ruby 3.1, but is used by the `mail` gem.
    # So we need to add them as dependencies until `mail` is fixed
    s.add_dependency 'net-smtp'
    s.add_dependency 'net-imap'
    s.add_dependency 'net-pop'
  end

  s.add_dependency 'aws-sdk-v1', '~> 1.45'
  s.add_dependency 'docile', '~> 1.1'
  s.add_dependency 'erubis', '~> 2.7', '>= 2.7.0'
  s.add_dependency 'gli', '~> 2.15'
  s.add_dependency 'highline', '= 2.0.0.pre.develop.14'
  s.add_dependency 'json_pure', '~> 2.6'
  s.add_dependency 'multi_json', '~> 1.12'
  s.add_dependency 'parseconfig', '~> 1.0'
  s.add_dependency 'pmap', '~> 1.1'
  s.add_dependency 'pry'
  s.add_dependency 'restforce', '>= 2.4'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'rubyzip'
  s.add_dependency 'salesforce_bulk_query', '~> 0.2', '>= 0.2.0'
  s.add_dependency 'terminal-table', '~> 1.7'
  s.add_dependency 'thread_safe'
end
