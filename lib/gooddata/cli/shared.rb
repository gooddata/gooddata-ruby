# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gli'

require_relative '../version'
require_relative '../core/core'
require_relative '../extensions/extensions'
require_relative '../exceptions/exceptions'
require_relative '../helpers/auth_helpers'

module GoodData
  module CLI
    extend GLI::App

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
    default_value GoodData::Helpers::AuthHelper.read_server
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
  end
end
