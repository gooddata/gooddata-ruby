# encoding: utf-8

require_relative '../version'
require_relative '../exceptions/exceptions'

module GoodData
  module Rest
    # Wrapper of low-level HTTP/REST client/library
    class Connection
      DEFAULT_URL = 'https://secure.gooddata.com'
      LOGIN_PATH = '/gdc/account/login'
      TOKEN_PATH = '/gdc/account/token'

      DEFAULT_HEADERS = {
        :content_type => :json,
        :accept => [:json, :zip],
        :user_agent => GoodData.gem_version_string
      }

      DEFAULT_LOGIN_PAYLOAD = {
        :headers => DEFAULT_HEADERS
      }

      class << self
        def construct_login_payload(username, password)
          res = {
            'postUserLogin' => {
              'login' => username,
              'password' => password,
              'remember' => 1
            }
          }
          res
        end
      end

      attr_reader :cookies
      attr_reader :stats
      attr_reader :user

      def initialize(opts)
        @user = nil

        @stats = {}

        # Initialize cookies
        reset_cookies!
      end

      # Connect using username and password
      def connect(username, password, options = {})
        # Reset old cookies first
        credentials = Connection.construct_login_payload(username, password)

        @auth = post(LOGIN_PATH, credentials, :dont_reauth => true)['userLogin']

        @user = get(@auth['profile'])
        refresh_token :dont_reauth => true
      end

      # Disconnect
      def disconnect
        # TODO: Wrap somehow
        url = @auth['state']
        delete url

        @auth = nil
        @server = nil
        @user = nil

        reset_cookies!
      end

      def refresh_token(options = {})
        begin # rubocop:disable RedundantBegin
          get TOKEN_PATH, :dont_reauth => true # avoid infinite loop GET fails with 401
        rescue Exception => e # rubocop:disable RescueException
          puts e.message
        end
      end

      # HTTP DELETE
      #
      # @param uri [String] Target URI
      def delete(uri, options = {})
        fail NotImplementedError "DELETE #{uri}"
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, options = {})
        fail NotImplementedError "GET #{uri}"
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, data, options = {})
        fail NotImplementedError "PUT #{uri}"
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, data, options = {})
        fail NotImplementedError "POST #{uri}"
      end

      private

      def merge_cookies!(cookies)
        @cookies[:cookies].merge! cookies
      end

      def profile(title, &block)
        t1 = Time.now
        res = block.call
        t2 = Time.now
        delta = t2 - t1

        update_stats title, delta
        res
      end

      def reset_cookies!
        @cookies = { :cookies => {} }
      end

      def update_stats(title, delta)
        stat = stats[title]
        if stat.nil?
          stat = {
            :min => delta,
            :max => delta,
            :total => 0,
            :avg => 0,
            :calls => 0,
          }
        end

        stat[:min] = delta if delta < stat[:min]
        stat[:max] = delta if delta > stat[:max]
        stat[:total] += delta
        stat[:calls] += 1
        stat[:avg] = stat[:total] / stat[:calls]

        stats[title] = stat
      end
    end
  end
end
