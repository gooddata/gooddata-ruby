require 'logger'
Dir[File.dirname(__FILE__) + '/**/*.rb'].each { |file| require file }

# Wrapper module for all GoodData classes. See the Base class for details.
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
  # Now it is just a matter of creating a new GoodData::Base object:
  #
  #   gd = GoodData::Base.new :username => 'gooddata_username',
  #                           :password => 'gooddata_password'
  #
  # This GoodData object can now be utalized to retrieve your GoodData profile, the available
  # projects etc.
  #
  class Base
    RELEASE_INFO_PATH = '/gdc/releaseInfo'

    # Creates a new GoodData API wrapper
    #
    # === Parameters
    #
    # * +attributes+ - A Hash of configuration attributes.
    #
    # ==== Possible attributes:
    #
    # * :username (required)
    # * :password (required)
    # * :log_level (defaults to :warn) - see GoodData.init_logger for possible values.
    #
    # The Hash keys can be both symbols and strings. So :username is just as good as 'username'.
    def initialize(attributes)
      attributes = attributes.inject({}) { |memo, (k,v)| memo[k.to_sym] = v; memo } # convert all attribute keys to symbols
      attributes = { :log_level => :warn }.merge attributes
      GoodData.init_logger attributes[:log_level]
      Connection.instance.set_credentials attributes[:username], attributes[:password]
    end

    # Returns the currently logged in user Profile.
    def profile
      @profile ||= Profile.load
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