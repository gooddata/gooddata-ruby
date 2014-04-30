# encoding: UTF-8

require_relative 'connection'

module GoodData
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
    #     GoodData.post '/gdc/projects', { ... }
    #
    def post(path, data, options = {})
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
    #     GoodData.put '/gdc/projects', { ... }
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

    def upload_to_user_webdav(file, options = {})
      u = URI(connection.options[:webdav_server] || GoodData.project.links['uploads'])
      url = URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
      connection.upload(file, options.merge(
        :directory => options[:directory],
        :staging_url => url
      ))
    end

    def get_project_webdav_path(file, options = {})
      u = URI(connection.options[:webdav_server] || GoodData.project.links['uploads'])
      URI.join(u.to_s.chomp(u.path.to_s), '/project-uploads/', "#{GoodData.project.pid}/")
    end

    def upload_to_project_webdav(file, options = {})
      url = get_project_webdav_path(file, options)
      connection.upload(file, options.merge(
        :directory => options[:directory],
        :staging_url => url))
    end

    def get_user_webdav_path(file, options = {})
      u = URI(connection.options[:webdav_server] || GoodData.project.links['uploads'])
      URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
    end

    def download_from_user_webdav(file, where, options = {})
      url = get_user_webdav_path(file, options)
      connection.download(file, where, options.merge(:staging_url => url))
    end

    def poll(result, key, options = {})
      sleep_interval = options[:sleep_interval] || 10
      link = result[key]['links']['poll']
      response = GoodData.get(link, :process => false)
      while response.code != 204
        sleep sleep_interval
        GoodData.connection.retryable(:tries => 3, :on => RestClient::InternalServerError) do
          sleep sleep_interval
          response = GoodData.get(link, :process => false)
        end
      end
    end

    def wait_for_polling_result(polling_url)
      polling_result = GoodData.get(polling_url)
      while polling_result['wTaskStatus'] && polling_result['wTaskStatus']['status'] == 'RUNNING'
        sleep(3)
        polling_result = GoodData.get(polling_url)
      end
      polling_result
    end

  end
end
