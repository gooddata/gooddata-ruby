# encoding: UTF-8

module GoodData
  DEFAULT_SLEEP_INTERVAL = 10

  class << self
    # Performs a HTTP GET request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    #
    # ### Examples
    #
    #     GoodData.get '/gdc/projects'
    #
    def get(path, options = {})
      connection.get(path, options)
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
    #     client.post '/gdc/projects', { ... }
    #
    def post(path, data = {}, options = {})
      connection.post path, data, options
    end

    # Performs a HTTP PUT request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # ### Parameters
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # @param data The payload data in the format of a Hash object
    #
    # ### Examples
    #
    #     client.put '/gdc/projects', { ... }
    #
    def put(path, data, options = {})
      connection.put path, data, options
    end

    # Performs a HTTP DELETE request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # @param path The HTTP path on the GoodData server (must be prefixed with a forward slash)
    #
    # ### Examples
    #
    #     GoodData.delete '/gdc/project/1'
    #
    def delete(path, options = {})
      connection.delete path, options
    end

    # Upload to user directory
    # @return [String]
    def upload_to_user_webdav(file, options = { :project => GoodData.project })
      options = merge_options(options)
      project = options[:project]
      u = URI(project.links['uploads'])
      url = URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')

      connection.upload(file, options.merge(
        :staging_url => url
      ))
    end

    # Get WebDav directory for project data
    # @return [String]
    def get_project_webdav_path(file, options = { :project => GoodData.project })
      options = merge_options(options)
      project = options[:project]
      project.get_project_webdav_path(file)
    end

    # Upload to project directory
    def upload_to_project_webdav(file, options = { :project => GoodData.project })
      options = merge_options(options)
      webdav_filename = File.basename(file)
      url = get_project_webdav_path(webdav_filename, options)
      connection.upload(file, options.merge(:staging_url => url))
    end

    # Download from project directory
    def download_from_project_webdav(file, where, options = { :project => GoodData.project })
      options = merge_options(options)
      url = get_project_webdav_path(file, options)
      connection.download(file, where, options.merge(:staging_url => url))
    end

    # Get WebDav directory for user data
    # @return [String]
    def get_user_webdav_path(file, options = { :project => GoodData.project })
      options = merge_options(options)
      project = options[:project]
      project.get_user_webdav_path(file)
    end

    # Download from user directory
    def download_from_user_webdav(file, where, options = { :project => GoodData.project })
      options = merge_options(options)
      url = get_user_webdav_path(file, options)
      connection.download(file, where, options.merge(:staging_url => url))
    end

    # Generalizaton of poller. Since we have quite a variation of how async proceses are handled
    # this is a helper that should help you with resources where the information about "Are we done"
    # is the http code of response. By default we repeat as long as the code == 202. You can
    # change the code if necessary. It expects the URI as an input where it can poll. It returns the
    # value of last poll. In majority of cases these are the data that you need.
    #
    # @param link [String] Link for polling
    # @param options [Hash] Options
    # @return [Hash] Result of polling
    def poll_on_code(link, options = {})
      code = options[:code] || 202
      sleep_interval = options[:sleep_interval] || DEFAULT_SLEEP_INTERVAL
      response = GoodData.get(link, :process => false)
      while response.code == code
        sleep sleep_interval
        GoodData::Rest::Client.retryable(:tries => 3, :refresh_token => proc { connection.refresh_token }) do
          sleep sleep_interval
          response = GoodData.get(link, :process => false)
        end
      end
      if options[:process] == false
        response
      else
        GoodData.get(link)
      end
    end

    # Generalizaton of poller. Since we have quite a variation of how async proceses are handled
    # this is a helper that should help you with resources where the information about "Are we done"
    # is inside the response. It expects the URI as an input where it can poll and a block that should
    # return either false -> 'meaning we are done' or true -> meaning sleep and repeat. It returns the
    # value of last poll. In majority of cases these are the data that you need
    #
    # @param link [String] Link for polling
    # @param options [Hash] Options
    # @return [Hash] Result of polling
    def poll_on_response(link, options = {}, &bl)
      client = options[:client]
      fail ArgumentError, 'No :client specified' if client.nil?

      sleep_interval = options[:sleep_interval] || DEFAULT_SLEEP_INTERVAL
      response = get(link)
      while bl.call(response)
        sleep sleep_interval
        GoodData::Rest::Client.retryable(:tries => 3, :refresh_token => proc { client.connection.refresh_token }) do
          sleep sleep_interval
          response = get(link)
        end
      end
      response
    end

    private

    def merge_options(opts)
      {
        :project => GoodData.project
      }.merge(opts)
    end
  end
end
