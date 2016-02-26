# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# GoodData Module
module GoodData
  VERSION = '0.6.25'

  class << self
    # Version
    def version
      VERSION
    end

    # Identifier of gem version
    # @return Formatted gem version
    def gem_version_string
      "gooddata-gem/#{VERSION}/#{RUBY_PLATFORM}/#{RUBY_VERSION}"
    end
  end
end
