require 'gli'

require File.join(File.dirname(__FILE__), "../version")

include GLI::App

program_desc 'GoodData Ruby gem - a wrapper over GoodData API and several useful abstractions to make your everyday usage of GoodData easier.'

version GoodData::VERSION

desc 'GoodData user name'
default_value nil
arg_name 'gooddata-login'
flag [:U, :username, :login]

desc 'GoodData password'
default_value nil
arg_name 'gooddata-password'
flag [:P, :password]

desc 'Project pid'
default_value nil
arg_name 'project-id'
flag [:p, :project_id]

desc 'Server'
default_value nil
arg_name 'server'
flag [:s, :server]

desc 'WEBDAV Server. Used for uploads of files'
default_value nil
arg_name 'web dav server'
flag [:w, :webdav_server]

desc 'Token for project creation'
default_value nil
arg_name 'token'
flag [:t, :token]

desc 'Verbose mode'
arg_name 'verbose'
switch [:v, :verbose]

desc 'Http logger on stdout'
arg_name 'logger'
switch [:l, :logger]
