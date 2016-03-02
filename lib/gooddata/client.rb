# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'csv'

require_relative 'version'
require_relative 'connection'
require_relative 'helpers/helpers'

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

require_relative 'core/core'

module GoodData
  class << self
    RELEASE_INFO_PATH = '/gdc/releaseInfo'

    # Initializes required dynamically loaded classes
    def init_module
      # Metadata packages, such as report.rb, require this to be loaded first
      require_relative 'models/metadata.rb'

      # Load models from models folder
      Dir[File.dirname(__FILE__) + '/models/*.rb'].each { |file| require file }

      # Load collections
      Dir[File.dirname(__FILE__) + '/collections/*.rb'].each { |file| require file }
    end

    # Returns information about the GoodData API as a Hash (e.g. version, release time etc.)
    def release_info
      @release_info ||= @connection.get(RELEASE_INFO_PATH)['release']
    end
  end
end

# Init requires
GoodData.init_module
