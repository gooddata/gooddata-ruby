require 'logger'
require 'gooddata/version'
require 'gooddata/connection'
Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |file| require file }
Dir[File.dirname(__FILE__) + '/collections/*.rb'].each { |file| require file }

# Wrapper module for all GoodData classes. See the Client class for details.
#
# == Logging
#
# The only thing contained directly in this module is logger object used to log all
# activity in the GoodData API wrapper. Before logging, the logger must
# first be initialized using the init_logger method. After initialization,
# an event can be logged using the logger attribute:
#
#   GoodData.logger.error 'Something bad happend!'
#
# For details about the logger options and methods, see the
# {Logger module documentation}[http://www.ruby-doc.org/stdlib/libdoc/logger/rdoc].
#
module GoodData
  class << self
    attr_accessor :logger

    # Prepare the Logger object. Logs to STDOUT.
    #
    # === Parameters
    #
    # * +level+ - the log level (:fatal, :error, :warn (default), :info, :debug)
    def init_logger(level = :warn)
      @logger = Logger.new(STDOUT)
      @logger.level = eval("Logger::#{level.to_s.upcase}")
    end
  end

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
  # Now it is just a matter of creating a new GoodData::Client object:
  #
  #   gd = GoodData::Client.new 'gooddata_user', 'gooddata_password'
  #
  # This GoodData object can now be utalized to retrieve your GoodData profile, the available
  # projects etc.
  #
  class Client
    RELEASE_INFO_PATH = '/gdc/releaseInfo'

    class << self
      def version
        GoodData::VERSION
      end

      def gem_version_string
        "gooddata-gem/#{version}"
      end
    end

    # Creates a new GoodData API wrapper
    #
    # === Parameters
    #
    # * +user+ - A GoodData username
    # * +password+ - A GoodData password
    # * +log_level+ - The desired loglevel (defaults to warn) - see GoodData.init_logger for possible values.
    #
    def initialize(user, password, log_level = :warn)
      GoodData.init_logger log_level
      Connection.instance.set_credentials user, password
    end

    def test_login
      GoodData::Connection.instance.connect!
      GoodData::Connection.instance.logged_in?
    end

    # Returns the currently logged in user Profile.
    def profile
      @profile ||= Profile.load
    end

    def find_project(id)
      Project.find(id)
    end

    # Returns an Array of projects.
    #
    # The Array is of type GoodData::Collections::Projects and each element is of type GoodData::Project.
    def projects
      @projects ||= profile.projects
    end

    # Returns information about the GoodData API as a Hash (e.g. version, release time etc.)
    def release_info
      @release_info ||= Connection.instance.get(RELEASE_INFO_PATH)['release']
    end
  end
end