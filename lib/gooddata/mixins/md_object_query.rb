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
        fail NotImplementedError, 'Method should be implemented in subclass. Currently there is no way how to get all metadata objects on API.'
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
      def query(query_obj_type, klass, options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        query_result = client.get(project.md['query'] + "/#{query_obj_type}/")['query']['entries']
        options[:full] == false ? query_result : query_result.pmap { |item| klass[item['link'], options] }
      end

      def dependency(uri, key = nil, opts = { :client => GoodData.connection })
        c = opts[:client]
        fail ArgumentError, 'No :client specified' if c.nil?

        result = c.get(uri)['entries']
        if key.nil?
          result
        elsif key.respond_to?(:category)
          result.select { |item| item['category'] == key.category }
        else
          result.select { |item| item['category'] == key }
        end
      end

      # Checks for dependency
      def dependency?(type, uri, target_uri, opts = { :client => GoodData.connection, :project => GoodData.project })
        uri = uri.respond_to?(:uri) ? uri.uri : uri
        objs = case type
               when :usedby
                 usedby(uri, nil, opts)
               when :using
                 using(uri, nil, opts)
               end

        target_uri = target_uri.respond_to?(:uri) ? target_uri.uri : target_uri
        objs.any? do |obj|
          obj['link'] == target_uri
        end
      end

      # Returns which objects uses this MD resource
      def usedby(uri, key = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'No :project specified' if project.nil?

        dependency("#{project.md['usedby2']}/#{obj_id(uri)}", key, opts)
      end

      alias_method :used_by, :usedby

      # Returns which objects this MD resource uses
      def using(uri, key = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'No :project specified' if project.nil?

        dependency("#{project.md['using2']}/#{obj_id(uri)}", key, opts)
      end

      def usedby?(uri, target_uri, opts = { :client => GoodData.connection, :project => GoodData.project })
        dependency?(:usedby, uri, target_uri, opts)
      end

      alias_method :used_by?, :usedby?

      # Checks if obj is using this MD resource
      def using?(uri, target_uri, opts = { :client => GoodData.connection, :project => GoodData.project })
        dependency?(:using, uri, target_uri, opts)
      end
    end
  end
end
