# encoding: UTF-8

require 'gli'
require 'pp'

require_relative '../helpers/auth_helpers'

GoodData::CLI.module_eval do
  pre do |global, _command, _options, _args|
    require 'logger'
    GoodData.logger = Logger.new(STDOUT) if global[:l]
    username = global[:username]
    password = global[:password]
    token = global[:token]

    creds = GoodData::Helpers::AuthHelper.read_credentials

    username = creds[:username] if username.nil?
    password = creds[:password] if password.nil?
    token = creds[:auth_token] || creds[:token] if token.nil?

    global[:token] = token if global[:token].nil?
    if global[:login].nil?
      global[:login] = username
      global['login'] = username
    end
    if global[:password].nil?
      global[:password] = password
      global['password'] = password
    end
    # Pre logic here
    # Return true to proceed; false to abort and not call the
    # chosen command
    # Use skips_pre before a command to skip this block
    # on that command only
    true
  end

  post do |_global, _command, _options, _args|
    # Post logic here
    # Use skips_post before a command to skip this
    # block on that command only
  end

  on_error do |_exception|
    # Error logic here
    # return false to skip default error handling
    # binding.pry
    # pp exception.backtrace
    # pp exception
    true
  end
end
