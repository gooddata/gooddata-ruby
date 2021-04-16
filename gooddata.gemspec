# encoding: utf-8
$LOAD_PATH.push File.expand_path('../lib/', __FILE__)
require 'gooddata/version'

Gem::Specification.new do |s|
  s.name = 'gooddata'
  s.version = GoodData::VERSION
  s.licenses = ['BSD-3-Clause']
  s.platform = 'java' if RUBY_PLATFORM =~ /java/

  s.required_rubygems_version = Gem::Requirement.new('>= 0') if s.respond_to? :required_rubygems_version=
  s.authors = [
    'Pavel Kolesnikov',
    'Thomas Watson Steen',
    'Tomas Svarovsky',
    'Tomas Korcak',
    'Jan Zdrahal',
    'Petr Gadorek',
    'Jakub Mahnert'
  ]

  s.summary = 'A convenient Ruby wrapper around the GoodData RESTful API'
  s.description = 'Use the GoodData::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.'
  s.email = 'lcm@gooddata.com'
  s.extra_rdoc_files = %w(LICENSE README.md)

  s.files = `git ls-files`.split($INPUT_RECORD_SEPARATOR).map { |f| f unless %w(NOTICES.txt LICENSE_FOR_RUBY_SDK_COMPONENT.txt).include?(f) }
  s.files.reject! { |fn| fn.start_with? 'spec/' }
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }

  s.homepage = 'http://github.com/gooddata/gooddata-ruby'
  s.require_paths = ['lib']

  # s.add_development_dependency 'bundler', "~> 1.14"
  s.add_development_dependency 'license_finder', '~> 2.0'
  s.add_development_dependency 'rake', '~> 11.1'
  s.add_development_dependency 'redcarpet', '~> 3.1' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'rspec', '~> 3.5.0'
  s.add_development_dependency 'rspec-expectations', '~> 3.5'
  s.add_development_dependency 'rspec_junit_formatter', '~> 0.3.0'
  s.add_development_dependency 'rubocop', '~> 0.59.1'
  s.add_development_dependency 'simplecov', '~> 0.12'
  s.add_development_dependency 'webmock', '~> 2.3.1'
  s.add_development_dependency 'yard', '~> 0.9.11'
  s.add_development_dependency 'yard-rspec', '~> 0.1'
  s.add_development_dependency 'pry'
  s.add_development_dependency 'pry-byebug', '~> 3.6' if RUBY_PLATFORM != 'java'

  s.add_development_dependency 'pronto', '~> 0.10' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'pronto-rubocop', '~> 0.9' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'pronto-reek', '~> 0.9' if RUBY_PLATFORM != 'java'
  s.add_development_dependency 'vcr', '5.0.0'
  s.add_development_dependency 'hashdiff', '~> 0.4'

  s.add_development_dependency 'sqlite3' if RUBY_PLATFORM != 'java'

  if RUBY_VERSION >= '2.5'
    s.add_dependency 'activesupport', '>= 6.0.3.1', '< 6.2'
  else
    s.add_dependency 'activesupport', '>= 5.2.4.3', '< 6.0'
  end

  s.add_dependency 'aws-sdk-s3', '~> 1.16'
  s.add_dependency 'docile', '~> 1.1'
  s.add_dependency 'gli', '~> 2.15'
  s.add_dependency 'gooddata_datawarehouse', '~> 0.0.10' if RUBY_PLATFORM == 'java'
  s.add_dependency 'highline', '= 2.0.0.pre.develop.14'
  s.add_dependency 'json_pure', '~> 1.8'
  s.add_dependency 'multi_json', '~> 1.12'
  s.add_dependency 'parseconfig', '~> 1.0'
  s.add_dependency 'pmap', '~> 1.1'
  s.add_dependency 'remote_syslog_logger', '~> 1.0.3'
  s.add_dependency 'restforce', '>= 2.4', '< 4.0'
  s.add_dependency 'rest-client', '~> 2.0'
  s.add_dependency 'rubyzip', '~> 1.2', '>= 1.2.1'
  s.add_dependency 'salesforce_bulk_query', '~> 0.2'
  s.add_dependency 'terminal-table', '~> 1.7'
  s.add_dependency 'thread_safe'
  s.add_dependency 'backports'
  s.add_dependency 'tty-spinner'
end
