module GoodData
  VERSION = "0.6.0.pre10"

  class << self

    # Version
    def version
      VERSION
    end

    # Identifier of gem version
    # @return Formatted gem version
    def gem_version_string()
      "gooddata-gem/#{VERSION}"
    end
  end
end
