# encoding: UTF-8

require_relative '../metadata'
require_relative '../../mixins/is_dimension'
require_relative 'metadata'

module GoodData
  class Dimension < GoodData::MdObject
    root_key :dimension

    include GoodData::Mixin::IsDimension

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('dimension', Dimension, options)
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id, opts = { client: GoodData.connection })
        return id if id.instance_of?(GoodData::Dimension) || id.respond_to?(:dimension?) && id.dimension?

        if id == :all
          Dimension.all({ client: GoodData.connection }.merge(opts))
        else
          uri = id

          c = client(opts)
          fail ArgumentError, 'No :client specified' if c.nil?

          response = c.get(uri)
          c.factory.create(Dimension, response)
        end
      end
    end

    def attributes
      content['attributes'].map do |attribute|
        client.create(Attribute, { 'attribute' => attribute }, project: project)
      end
    end
  end
end
