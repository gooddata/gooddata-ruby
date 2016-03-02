# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'uri'

require_relative 'core/logging'

require_relative 'rest/rest'

module GoodData
  class << self
    DEFAULT_SSO_OPTIONS = {
      :url => '/gdc/app/account/bootstrap',
      :valid => 24 * 60 * 60
    }

    # Returns the active GoodData connection earlier initialized via GoodData.connect call
    #
    # @see GoodData.connect
    def connection
      # TODO: Remove this after successful rest-factory transition
      Rest::Client.connection # || fail('Please authenticate with GoodData.connect first')
    end

    alias_method :client, :connection

    # Connect to the GoodData API
    #
    # @param options
    # @param second_options
    # @param third_options
    #
    def connect(options = nil, second_options = nil, third_options = {})
      Rest::Client.connect(options, second_options, third_options)
    end

    # Disconnect (logout) if logged in
    def disconnect
      Rest::Client.disconnect
    end

    def with_connection(options = nil, second_options = nil, third_options = {}, &bl)
      connection = connect(options, second_options, third_options)
      bl.call(connection)
    rescue Exception => e # rubocop:disable RescueException
      puts e.message
      raise e
    ensure
      disconnect
    end

    # Generates SSO URL
    #
    # This SSO implementation is custom implementation provided by GoodData
    # that allows your application to sign in an existing GoodData user.
    # The authentication is done not by username and password but by generating a session
    # specific token using pair of PGP keys.
    #
    # @see https://developer.gooddata.com/article/single-sign-on
    #
    # @param [String] login Email address used for logging into gooddata
    # @param [String] provider Name of SSO provider
    # @param [Hash] opts Additional options
    # @option opts [Fixnum] :validity Validity in seconds from 'now'
    # @return [String] URL which can be used for SSO logging in
    def sso_url(login, provider, opts = DEFAULT_SSO_OPTIONS)
      opts = DEFAULT_SSO_OPTIONS.merge(opts)

      ts = DateTime.now.strftime('%s').to_i + opts[:valid]
      obj = {
        'email' => login,
        'validity' => ts
      }

      json_data = JSON.pretty_generate(obj) + "\n"

      file_json = Tempfile.new('gooddata-sso-json')
      file_json.write(json_data)

      file_json.rewind
      file_signed = Tempfile.new('gooddata-sso-signed')

      cmd = "gpg --no-tty --armor --yes -u #{login} --output #{file_signed.path} --sign #{file_json.path}"
      res = system(cmd)
      fail 'Unable to sign json' unless res

      file_signed.rewind
      file_final = Tempfile.new('gooddata-sso-final')

      cmd = "gpg --yes --no-tty --trust-model always --armor --output #{file_final.path} --encrypt --recipient security@gooddata.com #{file_signed.path}"
      res = system(cmd)
      fail 'Unable to encrypt json' unless res

      file_final.rewind
      final = file_final.read

      "#{GoodData::Helpers::AuthHelper.read_server}/gdc/account/customerlogin?sessionId=#{CGI.escape(final)}&serverURL=#{CGI.escape(provider)}&targetURL=#{CGI.escape(opts[:url])}"
    end

    # Connect to GoodData using SSO
    #
    # This SSO implementation is custom implementation provided by GoodData
    # that allows your application to sign in an existing GoodData user.
    # The authentication is done not by username and password but by generating a session
    # specific token using pair of PGP keys.
    #
    # @see https://developer.gooddata.com/article/single-sign-on
    #
    # @param [String] login Email address used for logging into gooddata
    # @param [String] provider Name of SSO provider
    # @return [GoodData::Rest::Client] Instance of REST client
    def connect_sso(login, provider)
      url = sso_url(login, provider)

      params = {
        :x_gdc_request => "#{GoodData::Rest::Connection.generate_string}:#{GoodData::Rest::Connection.generate_string}"
      }

      RestClient.get url, params do |response, _request, _result|
        Rest::Client.connect_sso(:sst_token => URI.decode(response.cookies['GDCAuthSST']))
      end
    end
  end
end
