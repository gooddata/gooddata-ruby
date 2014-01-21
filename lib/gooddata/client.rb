require 'gooddata/version'
require 'gooddata/connection'
require 'active_support/core_ext/string'

# fastercsv is built in Ruby 1.9
if RUBY_VERSION < "1.9"
  require 'fastercsv'
else
  require 'csv'
  FasterCSV = CSV
end

# Metadata packages, such as report.rb, require this to be loaded first
require File.dirname(__FILE__) + '/models/metadata.rb'

Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/collections/*.rb'].each { |file| require file }

# = GoodData API wrapper
#
# A convenient Ruby wrapper around the GoodData RESTful API.
#
# The best documentation for the API can be found using these resources:
# * http://developer.gooddata.com/api
# * https://secure.gooddata.com/gdc
#
# == Usage
#
# To communicate with the API you first need a personal GoodData account.
# {Sign up here}[https://secure.gooddata.com/registration.html] if you havent already.
#
# Now it is just a matter of initializing the GoodData connection via the connect
# method:
#
#   GoodData.connect 'gooddata_user', 'gooddata_password'
#
# This GoodData object can now be utalized to retrieve your GoodData profile, the available
# projects etc.
#
# == Logging
#
#   GoodData.logger = Logger.new(STDOUT)
#
# For details about the logger options and methods, see the
# {Logger module documentation}[http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc].
#
module GoodData
  module Threaded
    # Used internally for thread safety
    def threaded
      Thread.current[:goooddata] ||= {}
    end
  end

  class NilLogger
    def debug(*args) ; end
    alias :info :debug
    alias :warn :debug
    alias :error :debug
  end

  def project=(project)
    GoodData.project = project
    GoodData.project
  end
  alias :use :project=

  class << self
    include Threaded

    RELEASE_INFO_PATH = '/gdc/releaseInfo'

    def version
      VERSION
    end

    def gem_version_string
      "gooddata-gem/#{version}"
    end

    # Connect to the GoodData API
    #
    # === Parameters
    #
    # * +user+ - A GoodData username
    # * +password+ - A GoodData password
    #
    def connect(options=nil, second_options=nil, third_options={})
      if options.is_a? Hash
        threaded[:connection] = Connection.new(options[:login], options[:password], options)
        GoodData.project = options[:project] if options[:project]
      elsif options.is_a?(String) && second_options.is_a?(String)
        threaded[:connection] = Connection.new(options, second_options, third_options)
      end
      
    end

    # Hepler for starting with SST easier
    # === Parameters
    #
    # * +token+ - SST token
    # * +options+ - options get routed to connect eventually so everything that you can use there should be possible to use here.
    #
    def connect_with_sst(token, options={})
      create_authenticated_connection(options.merge({:cookies => {"GDCAuthSST" => token}}))
    end

    # This method is aimed at creating an authenticated connection in case you do not hae pass/login but you have SST
    # === Parameters
    #
    # * +options+ - :server => optional GD server uri. If nil it secure will be used 
    # * +options+ - :cookies => you can specify a hash of cookies
    # 
    def create_authenticated_connection(options={})
      url = options[:server]

      connect("", "", url, options)
      server_cookies = options[:cookies]
      connection.merge_cookies!(server_cookies)
      connection.status = :logged_in
      connection
    end

    def with_project(project, &bl)
      old_project = GoodData.project
      begin
        GoodData.use(project)
        server_url = case GoodData.project.data["content"]["cluster"]
        when "na1"
          "https://na1.gooddata.com"
        else
          "https://secure.gooddata.com"
        end
        connection.url = server_url
        bl.call(project)
      rescue Exception => e
        fail e
      ensure
        GoodData.project = old_project
      end
    end

    # Returns the active GoodData connection earlier initialized via
    # GoodData.connect call
    #
    # @see GoodData.connect
    #
    def connection
      threaded[:connection] || raise("Please authenticate with GoodData.connect first")
    end

    # Sets the active project
    #
    # === Parameters
    #
    # * +project+ - a project identifier
    #
    # === Examples
    #
    # The following calls are equivalent:
    # * GoodData.project = 'afawtv356b6usdfsdf34vt'
    # * GoodData.use 'afawtv356b6usdfsdf34vt'
    # * GoodData.use '/gdc/projects/afawtv356b6usdfsdf34vt'
    # * GoodData.project = Project['afawtv356b6usdfsdf34vt']
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
    # === Parameters
    #
    # * +path+ - The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # === Examples
    #
    #   GoodData.get '/gdc/projects'
    def get(path, options = {})
      connection.get(path, options)
    end

    # Performs a HTTP POST request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # === Parameters
    #
    # * +path+ - The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # * +data+ - The payload data in the format of a Hash object
    #
    # === Examples
    #
    #   GoodData.post '/gdc/projects', { ... }
    def post(path, data, options = {})
      connection.post path, data, options
    end

    # Performs a HTTP PUT request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # === Parameters
    #
    # * +path+ - The HTTP path on the GoodData server (must be prefixed with a forward slash)
    # * +data+ - The payload data in the format of a Hash object
    #
    # === Examples
    #
    #   GoodData.put '/gdc/projects', { ... }
    def put(path, data, options = {})
      connection.put path, data, options
    end

    # Performs a HTTP DELETE request.
    #
    # Retuns the JSON response formatted as a Hash object.
    #
    # === Parameters
    #
    # * +path+ - The HTTP path on the GoodData server (must be prefixed with a forward slash)
    #
    # === Examples
    #
    #   GoodData.delete '/gdc/project/1'
    def delete(path, options = {})
      connection.delete path, options
    end

    def poll(result, key, options={})
      sleep_interval = options[:sleep_interval] || 10
      link = result[key]["links"]["poll"]
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
    # === Example
    #
    #   require 'logger'
    #   GoodData.logger = Logger.new(STDOUT)
    def logger
      @logger ||= NilLogger.new
    end

    # Sets the logger instance
    def logger=(logger)
      @logger = logger
    end
  end
end
