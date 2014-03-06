# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib/", __FILE__)
require "gooddata/version"

Gem::Specification.new do |s|
  s.name = %q{gooddata}
  s.version = GoodData::VERSION
  
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Pavel Kolesnikov", "Thomas Watson Steen"]
  s.summary = %q{A convenient Ruby wrapper around the GoodData RESTful API}
  s.date = %q{2012-12-17}
  s.description = %q{Use the GoodData::Client class to integrate GoodData into your own application or use the CLI to work with GoodData directly from the command line.}
  s.email = %q{pavel@gooddata.com}
  s.executables = ["gooddata"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.rdoc"
  ]
  s.files = `git ls-files`.split($/)
  s.homepage = %q{http://github.com/gooddata/gooddata-ruby}
  s.require_paths = ["lib"]
  s.rubygems_version = "1.3.7"

  s.add_development_dependency "active_support"
  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.add_dependency "bundler"
  s.add_dependency "parseconfig"
  s.add_dependency "json_pure"
  s.add_dependency "rest-client"
  s.add_dependency "json"
  s.add_dependency "rubyzip"
  s.add_dependency "highline"
  s.add_dependency "gli"
  s.add_dependency "pry"
  s.add_dependency "erubis"
  s.add_dependency "activesupport"
  s.add_dependency "restforce"
  s.add_dependency "salesforce_bulk"
  s.add_dependency "i18n"
  
end

