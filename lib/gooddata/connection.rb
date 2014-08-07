# encoding: UTF-8

require_relative 'core/connection'
require_relative 'core/logging'

require_relative 'rest/rest'

module GoodData
  class << self
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

    # Hepler for starting with SST easier
    #
    # @param token SST token
    # @param options Options get routed to connect eventually so everything that you can use there should be possible to use here.
    #
    def connect_with_sst(token, options = {})
      create_authenticated_connection(options.merge(:cookies => { 'GDCAuthSST' => token }))
    end

    # This method is aimed at creating an authenticated connection in case you do not hae pass/login but you have SST
    #
    # @param options :server => optional GD server uri, If nil it secure will be used. :cookies => you can specify a hash of cookies
    #
    def create_authenticated_connection(options = {})
      connect(options)
      server_cookies = options[:cookies]
      connection.merge_cookies!(server_cookies)
      connection.status = :logged_in
      connection
    end

    def with_connection(options = nil, second_options = nil, third_options = {}, &bl)
      connection = connect(options, second_options, third_options)
      bl.call(connection)
    ensure
      disconnect
    end
  end
end
