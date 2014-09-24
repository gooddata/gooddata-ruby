# encoding: UTF-8

require 'gli'
require 'pp'

require_relative '../helpers/auth_helpers'

GoodData::CLI.module_eval do
  pre do |global, command, options, args|
    require 'logger'
    GoodData.logger = Logger.new(STDOUT) if global[:l]
    username = global[:username]
    password = global[:password]
    token = global[:token]

    creds = GoodData::Helpers::AuthHelper.read_credentials

    username = creds[:username] if username.nil?
    password = creds[:password] if password.nil?
    token = creds[:auth_token] if token.nil?

    global[:token] = token if global[:token].nil?
    global[:login] = username if global[:login].nil?
    global[:password] = password if global[:password].nil?
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    true
  end

  post do |global, command, options, args|
    # Post logic here
    # Use skips_post before a command to skip this
    # block on that command only
  end

  on_error do |exception|
    # Error logic here
    # return false to skip default error handling
    # binding.pry
    pp exception.backtrace
    pp exception
    true
  end
end
