# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# GoodData Module
module GoodData
  SHA_PATH = File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'git-sha.txt'))

  VERSION = '0.6.23'
  VERSION_SHA = File.open(SHA_PATH).read

  class << self
    # Version
    def version
      VERSION
    end

    # Identifier of gem version
    # @return Formatted gem version
    def gem_version_string
      "gooddata-gem/#{VERSION}"
    end
  end
end
