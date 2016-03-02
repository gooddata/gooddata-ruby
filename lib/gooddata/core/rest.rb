# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
    def upload_to_user_webdav(file, options = {})
      url = user_webdav_path({ :client => GoodData.client }.merge(options))
      connection.upload(file, options.merge(staging_url: url))
    end

    # Get WebDav directory for project data
    # @return [String]
    def project_webdav_path(options = {})
      options = merge_options(options)
      project = options[:project]
      project.project_webdav_path
    end

    # Upload to project directory
    def upload_to_project_webdav(file, options = {})
      options = merge_options(options)
      url = project_webdav_path(options)
      connection.upload(file, options.merge(:staging_url => url))
    end

    # Download from project directory
    def download_from_project_webdav(file, where, options = {})
      options = merge_options(options)
      url = project_webdav_path(options)
      connection.download(file, where, options.merge(:staging_url => url))
    end

    # Get WebDav directory for user data
    # @return [String]
    def user_webdav_path(options = {})
      client = GoodData::Rest::Object.client({ :client => GoodData.client }.merge(options))
      client.user_webdav_path
    end

    # Download from user directory
    def download_from_user_webdav(file, where, options = {})
      url = user_webdav_path({ :client => GoodData.client }.merge(options))
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
      client = options[:client]
      fail ArgumentError, 'No :client specified' if client.nil?
      client.poll_on_code(link, options)
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
      client.poll_on_response(link, options, &bl)
    end

    private

    def merge_options(opts)
      {
        :project => GoodData.project
      }.merge(opts)
    end
  end
end
