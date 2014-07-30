# encoding: UTF-8

module GoodData
  module Mixin
    module MdObjectQuery
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = {})
        fail NotImplementedError, 'Method should be implemented in subclass. Currently there is no way hoe to get all metadata objects on API.'
      end

      # Method intended to be called by individual classes in their all
      # implementations. It abstracts the way interacting with query resources.
      # It either returns the array of hashes from query. If asked it also
      # goes and brings the full objects. Due to performance reasons
      # :full => false is the default. This will most likely change
      #
      # @param query_obj_type [String] string used in URI to distinguish different query resources for different objects
      # @param klass [Class] A class used for instantiating the returned data
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def query(query_obj_type, klass, options = {})
        fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
        query_result = GoodData.get(GoodData.project.md['query'] + "/#{query_obj_type}/")['query']['entries']
        options[:full] ? query_result.map { |item| klass[item['link']] } : query_result
      end

      def dependency(uri, key = nil)
        result = GoodData.get(uri)['entries']
        if key.nil?
          result
        elsif key.respond_to?(:category)
          result.select { |item| item['category'] == key.category }
        else
          result.select { |item| item['category'] == key }
        end
      end

      # Checks for dependency
      def dependency?(type, uri)
        objs = case type
               when :usedby
                 usedby(uri)
               when :using
                 using(uri)
               end
        uri = uri.respond_to?(:uri) ? uri.uri : uri
        objs.any? { |obj| obj['link'] == uri }
      end

      # Returns which objects uses this MD resource
      def usedby(uri, key = nil, project = GoodData.project)
        dependency("#{project.md['usedby2']}/#{obj_id(uri)}", key)
      end

      alias_method :used_by, :usedby

      # Returns which objects this MD resource uses
      def using(uri, key = nil)
        dependency("#{GoodData.project.md['using2']}/#{obj_id(uri)}", key)
      end

      def usedby?(obj)
        dependency?(:usedby, obj)
      end

      alias_method :used_by?, :usedby?

      # Checks if obj is using this MD resource
      def using?(obj)
        dependency?(:using, obj)
      end
    end
  end
end
