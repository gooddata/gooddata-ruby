# encoding: UTF-8

require_relative '../metadata'

module GoodData
  class Dataset < MdObject
    root_key :dataSet

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('dataSet', Dataset, options)
      end
    end

    # Gives you list of attributes on a dataset
    #
    # @return [Array<GoodData::Attribute>]
    def attributes
      attribute_uris.pmap { |a_uri| project.attributes(a_uri) }
    end

    # Gives you list of attribute uris on a dataset
    #
    # @return [Array<String>]
    def attribute_uris
      content['attributes']
    end

    # Gives you list of facts on a dataset
    #
    # @return [Array<GoodData::Fact>]
    def facts
      fact_uris.pmap { |a_uri| project.facts(a_uri) }
    end

    # Gives you list of fact uris on a dataset
    #
    # @return [Array<String>]
    def fact_uris
      content['facts']
    end

    # Tells you if a dataset is a date dimension. This is done by looking at
    # the attributes and inspecting their identifiers.
    #
    # @return [Boolean]
    def date_dimension?
      attributes.all?(&:date_attribute?) && fact_uris.empty?
    end

    # Delete the data in a dataset
    def synchronize
      project.execute_maql("SYNCHRONIZE {#{identifier}}")
    end
    alias_method :delete_data, :synchronize
  end
end
