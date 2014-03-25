# encoding: UTF-8

require_relative 'version'
require_relative 'connection'
require_relative 'helpers'

# fastercsv is built in Ruby 1.9
if RUBY_VERSION < '1.9'
  require 'fastercsv'
else
  require 'csv'
  FasterCSV = CSV
end

# Initializes required dynamically loaded classes
def init_gd_module()
  # Metadata packages, such as report.rb, require this to be loaded first
  require_relative 'models/metadata.rb'

  # Load models from models folder
  Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |file| require file }

  # Load collections
  Dir[File.dirname(__FILE__) + '/collections/*.rb'].each { |file| require file }
end

init_gd_module()

# # GoodData API wrapper
#
# A convenient Ruby wrapper around the GoodData RESTful API.
#
# The best documentation for the API can be found using these resources:
#
# * http://developer.gooddata.com/api
# * https://secure.gooddata.com/gdc
#
# ## Usage
#
# To communicate with the API you first need a personal GoodData account.
# [Sign up here](https://secure.gooddata.com/registration.html) if you havent already.
#
# Now it is just a matter of initializing the GoodData connection via the connect method:
#
#     GoodData.connect 'gooddata_user', 'gooddata_password'
#
# This GoodData object can now be utalized to retrieve your GoodData profile, the available
# projects etc.
#
# ## Logging
#
#     GoodData.logger = Logger.new(STDOUT)
#
# For details about the logger options and methods, see the
# (Logger module documentation)[http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc].
#
module GoodData
  module Threaded
    # Used internally for thread safety
    def threaded
      Thread.current[:goooddata] ||= {}
    end
  end

  # Dummy implementation of logger
  class NilLogger
    def debug(*args)
      ;
    end

    alias :info :debug
    alias :warn :debug
    alias :error :debug
  end

  # Assigns global/default GoodData project
  def project=(project)
    GoodData.project = project
    GoodData.project
  end

  alias :use :project=

  class << self
    include Threaded

    RELEASE_INFO_PATH = '/gdc/releaseInfo'

    # Connect to the GoodData API
    #
    # @param options
    # @param second_options
    # @param third_options
    #
    def connect(options=nil, second_options=nil, third_options={})
      if options.is_a? Hash
        fail 'You have to provide login and password' if ((options[:login].nil? || options[:login].empty?) && (options[:password].nil? || options[:password].empty?))
        threaded[:connection] = Connection.new(options[:login], options[:password], options)
        GoodData.project = options[:project] if options[:project]
      elsif options.is_a?(String) && second_options.is_a?(String)
        fail 'You have to provide login and password' if ((options.nil? || options.empty?) && (second_options.nil? || second_options.empty?))
        threaded[:connection] = Connection.new(options, second_options, third_options)
      end

      return threaded[:connection]
    end

    # Disconnect (logout) if logged in
    def disconnect
      if threaded[:connection]
        threaded[:connection].disconnect
        threaded[:connection] = nil
      end
    end

    # Turn logging on
    def logging_on
      if logger.is_a? NilLogger
        GoodData::logger = Logger.new(STDOUT)
      end
    end

    # Turn logging off
    def logging_off
      GoodData::logger = NilLogger.new
    end


    # Hepler for starting with SST easier
    #
    # @param token SST token
    # @param options Options get routed to connect eventually so everything that you can use there should be possible to use here.
    #
    def connect_with_sst(token, options={})
      create_authenticated_connection(options.merge({:cookies => {'GDCAuthSST' => token}}))
    end

    # This method is aimed at creating an authenticated connection in case you do not hae pass/login but you have SST
    #
    # @param options :server => optional GD server uri, If nil it secure will be used. :cookies => you can specify a hash of cookies
    #
    def create_authenticated_connection(options={})
      connect(options)
      server_cookies = options[:cookies]
      connection.merge_cookies!(server_cookies)
      connection.status = :logged_in
      connection
    end

    # Perform block in context of another project than currently set
    #
    # @param project Project to use
    # @param bl Block to be performed
    def with_project(project, &bl)
      fail 'You have to specify a project when using with_project' if project.nil? || (project.is_a?(String) && project.empty?)
      old_project = GoodData.project
      begin
        GoodData.use(project)
        bl.call(GoodData.project)
      rescue RestClient::ResourceNotFound => e
        fail GoodData::ProjectNotFound.new(e)
      ensure
        GoodData.project = old_project
      end
    end

    # Returns the active GoodData connection earlier initialized via GoodData.connect call
    #
    # @see GoodData.connect
    def connection
      threaded[:connection] || raise('Please authenticate with GoodData.connect first')
    end

    # Sets the active project
    #
    # @param project A project identifier
    #
    # ### Examples
    #
    # The following calls are equivalent
    #
    #     # Assign project ID
    #     GoodData.project = 'afawtv356b6usdfsdf34vt'
    #
    #     # Use project ID
    #     GoodData.use 'afawtv356b6usdfsdf34vt'
    #
    #     # Use project URL
    #     GoodData.use '/gdc/projects/afawtv356b6usdfsdf34vt'
    #
    #     # Select project using indexer on GoodData::Project class
    #     GoodData.project = Project['afawtv356b6usdfsdf34vt']
    #
    def project=(project)
      if project.is_a? Project
        threaded[:project] = project
      elsif project.nil?
        threaded[:project] = nil
      else
        threaded[:project] = Project[project]
      end
    end

    alias :use :project=

    # Returns the active project
    #
    def project
      threaded[:project]
    end

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

    def upload_to_user_webdav(file, options={})
      u = URI(connection.options[:webdav_server] || GoodData.project.links['uploads'])
      url = URI.join(u.to_s.chomp(u.path.to_s), '/uploads/')
      connection.upload(file, options.merge({
                                              :directory => options[:directory],
                                              :staging_url => url
                                            }))
    end

    def get_project_webdav_path(file, options={})
      u = URI(connection.options[:webdav_server] || GoodData.project.links["uploads"])
      url = URI.join(u.to_s.chomp(u.path.to_s), "/project-uploads/", "#{GoodData.project.pid}/")
    end

    def upload_to_project_webdav(file, options={})
      url = get_project_webdav_path(file, options)
      connection.upload(file, options.merge({
                                              :directory => options[:directory],
                                              :staging_url => url
                                            }))
    end

    def get_user_webdav_path(file, options={})
      u = URI(connection.options[:webdav_server] || GoodData.project.links["uploads"])
      url = URI.join(u.to_s.chomp(u.path.to_s), "/uploads/")
    end

    def download_from_user_webdav(file, where, options={})
      url = get_user_webdav_path(file, options)
      connection.download(file, where, options.merge({
                                                       :staging_url => url
                                                     }))
    end

    def poll(result, key, options={})
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

    def test_login
      connection.connect!
      connection.logged_in?
    end

    # Returns the currently logged in user Profile.
    def profile
      threaded[:profile] ||= Profile.load
    end

    # Returns information about the GoodData API as a Hash (e.g. version, release time etc.)
    def release_info
      @release_info ||= @connection.get(RELEASE_INFO_PATH)['release']
    end

    # Returns the logger instance. The default implementation
    # does not log anything
    # For some serious logging, set the logger instance using
    # the logger= method
    #
    # ### Example
    #
    #     require 'logger'
    #     GoodData.logger = Logger.new(STDOUT)
    #
    def logger
      @logger ||= NilLogger.new
    end

    # Sets the logger instance
    def logger=(logger)
      @logger = logger
    end
  end
end
