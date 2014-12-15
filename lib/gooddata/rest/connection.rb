# encoding: utf-8

require 'terminal-table'

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
        @opts = opts

        # Initialize cookies
        reset_cookies!

        @at_exit_handler = nil
      end

      # Connect using username and password
      def connect(username, password, options = {})
        # Install at_exit handler first
        unless @at_exit_handler
          @at_exit_handler = proc {
            disconnect if @user
          }
          at_exit &@at_exit_handler
        end

        # Reset old cookies first
        if options[:sst_token]
          merge_cookies!('GDCAuthSST' => options[:sst_token])
          @user = get(get('/gdc/app/account/bootstrap')['bootstrapResource']['accountSetting']['links']['self'])
          @auth = {}
          refresh_token :dont_reauth => true
        else
          credentials = Connection.construct_login_payload(username, password)
          @auth = post(LOGIN_PATH, credentials, :dont_reauth => true)['userLogin']

          @user = get(@auth['profile'])
          refresh_token :dont_reauth => true
        end
      end

      # Disconnect
      def disconnect
        # TODO: Wrap somehow
        url = @auth['state']
        delete url if url

        @auth = nil
        @server = nil
        @user = nil

        reset_cookies!
      end

      def refresh_token(_options = {})
        begin # rubocop:disable RedundantBegin
          get TOKEN_PATH, :dont_reauth => true # avoid infinite loop GET fails with 401
        rescue Exception => e # rubocop:disable RescueException
          puts e.message
          raise e
        end
      end

      # Returns server URI
      #
      # @return [String] server uri
      def server_url
        @server && @server.url
      end

      # HTTP DELETE
      #
      # @param uri [String] Target URI
      def delete(uri, _options = {})
        fail NotImplementedError "DELETE #{uri}"
      end

      # HTTP GET
      #
      # @param uri [String] Target URI
      def get(uri, _options = {})
        fail NotImplementedError "GET #{uri}"
      end

      # HTTP PUT
      #
      # @param uri [String] Target URI
      def put(uri, _data, _options = {})
        fail NotImplementedError "PUT #{uri}"
      end

      # HTTP POST
      #
      # @param uri [String] Target URI
      def post(uri, _data, _options = {})
        fail NotImplementedError "POST #{uri}"
      end

      # Reader method for SST token
      #
      # @return uri [String] SST token
      def sst_token
        cookies[:cookies]['GDCAuthSST']
      end

      def stats_table(values = stats)
        sorted = values.sort_by { |_k, v| v[:avg] }
        Terminal::Table.new :headings => %w(title avg min max total calls) do |t|
          sorted.each do |l|
            row = [
              l[0],
              sprintf('%.3f', l[1][:avg]),
              sprintf('%.3f', l[1][:min]),
              sprintf('%.3f', l[1][:max]),
              sprintf('%.3f', l[1][:total]),
              l[1][:calls]
            ]
            t.add_row row
          end
        end
      end

      # Reader method for TT token
      #
      # @return uri [String] TT token
      def tt_token
        cookies[:cookies]['GDCAuthTT']
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

      def scrub_params(params, keys)
        keys = keys.reduce([]) { |a, e| a.concat([e.to_s, e.to_sym]) }

        new_params = params.deep_dup
        GoodData::Helpers.hash_dfs(new_params) do |k, _key|
          keys.each do |key_to_scrub|
            k[key_to_scrub] = ('*' * k[key_to_scrub].length) if k && k.key?(key_to_scrub) && k[key_to_scrub]
          end
        end
        new_params
      end

      # TODO: Store PH_MAP for wildcarding of URLs in reports in separate file
      PH_MAP = [
        ['/gdc/projects/{id}/users/{id}/permissions', %r{/gdc/projects/[\w]+/users/[\w]+/permissions}],
        ['/gdc/projects/{id}/roles/{id}', %r{/gdc/projects/[\w]+/roles/[\d]+}],
        ['/gdc/projects/{id}/model/diff/{id}', %r{/gdc/projects/[\w]+/model/diff/[\w]+}],
        ['/gdc/projects/{id}/', %r{/gdc/projects/[\w]+/}],
        ['/gdc/projects/{id}', %r{/gdc/projects/[\w]+}],
        ['/gdc/md/{id}/using2/{id}/{id}', %r{/gdc/md/[\w]+/using2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/tasks/{id}/status', %r{/gdc/md/[\w]+/tasks/[\w]+/status}],
        ['/gdc/md/{id}/obj/{id}/validElements', %r{/gdc/md/[\w]+/obj/[\d]+/validElements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}/elements', %r{/gdc/md/[\w]+/obj/[\d]+/elements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}', %r{/gdc/md/[\w]+/obj/[\d]+}],
        ['/gdc/md/{id}/etl/task/{id}', %r{/gdc/md/[\w]+/etl/task/[\d]+}],
        ['/gdc/md/{id}/dataResult/{id}', %r{/gdc/md/[\w]+/dataResult/[\d]+}],
        ['/gdc/md/{id}', %r{/gdc/md/[\w]+}],
        ['/gdc/app/projects/{id}/execute', %r{/gdc/app/projects/[\w]+/execute}],
        ['/gdc/account/profile/{id}', %r{/gdc/account/profile/[\w]+}],
        ['/gdc/account/login/{id}', %r{/gdc/account/login/[\w]+}],
        ['/gdc/account/domains/{id}', %r{/gdc/account/domains/[\w\d-]+}]
      ]

      def update_stats(title, delta)
        orig_title = title

        placeholders = true

        if placeholders
          PH_MAP.each do |pm|
            break if title.gsub!(pm[1], pm[0])
          end
        end

        stat = stats[title]
        if stat.nil?
          stat = {
            :min => delta,
            :max => delta,
            :total => 0,
            :avg => 0,
            :calls => 0,
            :entries => []
          }
        end

        stat[:min] = delta if delta < stat[:min]
        stat[:max] = delta if delta > stat[:max]
        stat[:total] += delta
        stat[:calls] += 1
        stat[:avg] = stat[:total] / stat[:calls]

        stat[:entries] << orig_title if placeholders

        stats[title] = stat
      end
    end
  end
end
