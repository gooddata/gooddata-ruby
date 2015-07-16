# encoding: UTF-8

# GoodData Module
module GoodData
  VERSION = '0.6.20'

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
