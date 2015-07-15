# encoding: UTF-8

module GoodData
  class UserFilter < GoodData::MdObject
    def initialize(data)
      @dirty = false
      @json = GoodData::Helpers.symbolize_keys(data)
    end

    def ==(other)
      other.class == self.class && other.related_uri == related_uri && other.expression == expression
    end
    alias_method :eql?, :==

    def hash
      [related_uri, expression].hash
    end

    # Returns the uri of the object this filter is related to. It can be either project or a user
    #
    # @return [String] Uri of related object
    def related_uri
      @json[:related]
    end

    # Returns the the object of this filter is related to. It can be either project or a user
    #
    # @return [GoodData::Project | GoodData::Profile] Related object
    def related
      uri = related_uri
      level == :project ? client.projects(uri) : client.create(GoodData::Profile, client.get(uri))
    end

    # Returns the the object of this filter is related to. It can be either project or a user
    #
    # @return [GoodData::Project | GoodData::Profile] Related object
    def variable
      uri = @json[:prompt]
      GoodData::Variable[uri, client: client, project: project]
    end

    # Returns the level this filter is applied on. Either project or user. This is useful for
    # variables where you can have both types. Project level is the default that is applied when
    # user does not have assigned a value. When both user and project value and user value is missing
    # value, you will get 'uncomputable report' errors.
    #
    # @return [Symbol] level on which this filter will be applied
    def level
      @json[:level].to_sym
    end

    # Returns the MAQL expression of the filter
    #
    # @return [String] MAQL expression
    def expression
      @json[:expression]
    end

    # Allows to set the MAQL expression of the filter
    #
    # @param expression [String] MAQL expression
    # @return [String] MAQL expression
    def expression=(expression)
      @dirty = true
      @json[:expression] = expression
    end

    # Gives you URI of the filter
    #
    # @return [String]
    def uri
      @json[:uri]
    end

    # Allows to set URI of the filter
    #
    # @return [String]
    def uri=(uri)
      @json[:uri] = uri
    end

    # Returns pretty version of the expression
    #
    # @return [String]
    def pretty_expression
      SmallGoodZilla.pretty_print(expression, client: client, project: project)
    end

    # Deletes the filter from the server
    #
    # @return [String]
    def delete
      client.delete(uri)
    end
  end
end
