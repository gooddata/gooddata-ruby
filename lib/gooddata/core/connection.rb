# encoding: UTF-8

require 'multi_json'
require 'rest-client'

require_relative '../version'

module GoodData
  # # GoodData HTTP wrapper
  #
  # Provides a convenient HTTP wrapper for talking with the GoodData API.
  #
  # Remember that the connection is shared amongst the entire application.
  # Therefore you can't be logged in to more than _one_ GoodData account.
  # per session. Simultaneous connections to multiple GoodData accounts is not
  # supported at this time.
  #
  # The GoodData API is a RESTful API that communicates using JSON. This wrapper
  # makes sure that the session is stored between requests and that the JSON is
  # parsed both when sending and receiving.
  #
  # ## Usage
  #
  # Before a connection can be made to the GoodData API, you have to supply the user credentials like this:
  #
  #   Connection.new(username, password)
  #
  # To send a HTTP request use either the get, post or delete methods documented below.
  #
  class Connection
    DEFAULT_URL = 'https://secure.gooddata.com'
    LOGIN_PATH = '/gdc/account/login'
    TOKEN_PATH = '/gdc/account/token'

    attr_reader(:auth_token, :url)
    attr_accessor :status, :options

    # Options:
    # * :tries - Number of retries to perform. Defaults to 1.
    # * :on - The Exception on which a retry will be performed. Defaults to Exception, which retries on any Exception.
    #
    # ### Example
    #
    #     retryable(:tries => 1, :on => OpenURI::HTTPError) do
    #       # your code here
    #     end
    #
    def retryable(options = {}, &block)
      opts = { :tries => 1, :on => Exception }.merge(options)

      retry_exception, retries = opts[:on], opts[:tries]

      begin
        return yield
      rescue retry_exception
        retry if (retries -= 1) > 0
      end

      yield
    end

    # Set the GoodData account credentials.
    #
    # This have to be performed before any calls to the API.
    #
    # @param username The GoodData account username
    # @param password The GoodData account password
    #
    def initialize(username, password, options = {})
      @status = :not_connected
      @username = username
      @password = password
      @url = options[:server] || DEFAULT_URL
      @auth_token = options[:gdc_temporary_token]
      @options = options
      @server = create_server_connection(@url, @options)
    end

    # Returns the user JSON object of the currently logged in GoodData user account.
    def user
      ensure_connection
      @user
    end

    # Performs a HTTP GET request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    #
    # ### Examples
    #
    #     Connection.new(username, password).get '/gdc/projects'
    #
    def get(path, options = {})
      GoodData.logger.debug "GET #{@server}#{path}"
      ensure_connection
      b = proc { @server[path].get cookies }
      process_response(options, &b)
    end

    # Performs a HTTP POST request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # @param data The payload data in the format of a Hash object
    #
    # ### Examples
    #
    #     Connection.new(username, password).post '/gdc/projects', { ... }
    #
    def post(path, data, options = {})
      GoodData.logger.debug("POST #{@server}#{path}, payload: #{scrub_params(data, [:password, :login, :authorizationToken])}")
      ensure_connection
      payload = data.is_a?(Hash) ? data.to_json : data
      b = proc { @server[path].post payload, cookies }
      process_response(options, &b)
    end

    # Performs a HTTP PUT request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # @param data The payload data in the format of a Hash object
    #
    # ### Examples
    #
    #     Connection.new(username, password).put '/gdc/projects', { ... }
    #
    def put(path, data, options = {})
      payload = data.is_a?(Hash) ? data.to_json : data
      GoodData.logger.debug "PUT #{@server}#{path}, payload: #{payload}"
      ensure_connection
      b = proc { @server[path].put payload, cookies }
      process_response(options, &b)
    end

    # Performs a HTTP DELETE request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    #
    # ### Examples
    #
    #     Connection.new(username, password).delete '/gdc/project/1'
    #
    def delete(path, options = {})
      GoodData.logger.debug "DELETE #{@server}#{path}"
      ensure_connection
      b = proc { @server[path].delete cookies }
      process_response(options, &b)
    end

    # Get the cookies associated with the current connection.
    def cookies
      @cookies ||= { :cookies => {} }
    end

    # Set the cookies used when communicating with the GoodData API.
    def merge_cookies!(cookies)
      self.cookies
      @cookies[:cookies].merge! cookies
    end

    # Returns true if a connection have been established to the GoodData API
    # and the login was successful.
    def logged_in?
      @status == :logged_in
    end

    def url=(url = nil)
      @url = url || DEFAULT_URL
      @server = create_server_connection(@url, @options)
    end

    # The connection will automatically be established once it's needed, which it
    # usually is when either the user, get, post or delete method is called. If you
    # want to force a connection (or a re-connect) you can use this method.
    def connect!
      connect
    end

    # Uploads a file to GoodData server
    # /uploads/ resources are special in that they use a different
    # host and a basic authentication.
    def upload(file, options = {})
      ensure_connection

      dir = options[:directory] || ''
      staging_uri = options[:staging_url].to_s
      url = dir.empty? ? staging_uri : URI.join(staging_uri, "#{dir}/").to_s

      # Make a directory, if needed
      unless dir.empty?
        method = :get
        GoodData.logger.debug "#{method}: #{url}"
        begin
          # first check if it does exits
          RestClient::Request.execute({
            :method => method,
            :url => url,
            :timeout => @options[:timeout],
            :headers => {
              :user_agent => GoodData.gem_version_string
              }
            }.merge(cookies)
          )
        rescue RestClient::Exception => e
          if e.http_code == 404
            method = :mkcol
            GoodData.logger.debug "#{method}: #{url}"
            RestClient::Request.execute({
              :method => method,
              :url => url,
              :timeout => @options[:timeout],
              :headers => {
                :user_agent => GoodData.gem_version_string
              }
            }.merge(cookies))
          end
        end
      end

      payload = options[:stream] ? 'file' : File.read(file)
      filename = options[:filename] || options[:stream] ? 'randome-filename.txt' : File.basename(file)

      # Upload the file
      # puts "uploading the file #{URI.join(url, filename).to_s}"
      req = RestClient::Request.new(
        :method => :put,
        :url => URI.join(url, filename).to_s,
        :timeout => @options[:timeout],
        :headers => {
          :user_agent => GoodData.gem_version_string
        },
        :payload => payload,
        :raw_response => true,
        :user => @username,
        :password => @password
      )
      # .merge(cookies))
      req.execute
      true
    end

    def download(what, where, options = {})
      staging_uri = options[:staging_url].to_s
      url = staging_uri + what
      req = RestClient::Request.new(
        :method => 'GET',
        :url => url,
        :user => @username,
        :password => @password)

      if where.is_a?(String)
        File.open(where, 'w') do |f|
          req.execute do |chunk, x, y|
            f.write chunk
          end
        end
      else
        # Assume it is a IO stream
        req.execute do |chunk, x, y|
          where.write chunk
        end
      end
    end

    def connected?
      @status == :logged_in
    end

    def disconnect
      if connected? && GoodData.connection.user['state']
        GoodData.delete(GoodData.connection.user['state'])
        @status = :not_connected
      end
    end

    private

    def create_server_connection(url, options)
      @headers = options[:headers] || {}

      default_headers = {
          :content_type => :json,
          :accept => [:json, :zip],
          :user_agent => GoodData.gem_version_string
      }
      default_headers.merge! @headers

      RestClient::Resource.new url,
                               :timeout => options[:timeout],
                               :headers => default_headers
    end

    def ensure_connection
      connect if @status == :not_connected
    end

    def connect
      GoodData.logger.info 'Connecting to GoodData...'
      @status = :connecting
      authenticate
    end

    def authenticate
      credentials = {
        'postUserLogin' => {
          'login' => @username,
          'password' => @password,
          'remember' => 1
        }
      }
      GoodData.logger.debug 'Logging in...'
      @user = post(LOGIN_PATH, credentials, :dont_reauth => true)['userLogin']
      refresh_token :dont_reauth => true # avoid infinite loop if refresh_token fails with 401

      @status = :logged_in
    end

    def process_response(options = {}, &block)
      begin
        response = block.call
      rescue RestClient::Unauthorized
        raise $ERROR_INFO if options[:dont_reauth]
        refresh_token
        response = block.call
      end
      merge_cookies! response.cookies
      content_type = response.headers[:content_type]
      return response if options[:process] == false

      if content_type == 'application/json' || content_type == 'application/json;charset=UTF-8'
        result = response.to_str == '""' ? {} : MultiJson.load(response.to_str)
        GoodData.logger.debug "Response: #{result.inspect}"
      elsif content_type == 'application/zip'
        result = response
        GoodData.logger.debug 'Response: a zipped stream'
      elsif response.headers[:content_length].to_s == '0'
        result = nil
        GoodData.logger.debug 'Response: Empty response possibly 204'
      elsif response.code == 204
        result = nil
        GoodData.logger.debug 'Response: 204 no content'
      else
        fail "Unsupported response content type '%s':\n%s" % [content_type, response.to_str[0..127]]
      end
      result
    rescue RestClient::Exception => e
      GoodData.logger.debug "Response: #{e.response}"
      raise $ERROR_INFO
    end

    def refresh_token(options = {})
      GoodData.logger.debug 'Getting authentication token...'
      begin
        get TOKEN_PATH, :dont_reauth => true # avoid infinite loop GET fails with 401
      rescue RestClient::Unauthorized
        raise $ERROR_INFO if options[:dont_reauth]
        authenticate
      end
    end

    def scrub_params(params, keys)
      keys = keys.reduce([]) { |a, e| a.concat([e.to_s, e.to_sym]) }

      new_params = params.deep_dup
      GoodData::Helpers.hash_dfs(new_params) do |k, key|
        keys.each do |key_to_scrub|
          k[key_to_scrub] = ('*' * k[key_to_scrub].length) if k && k.key?(key_to_scrub) && k[key_to_scrub]
        end
      end
      new_params
    end
  end
end
