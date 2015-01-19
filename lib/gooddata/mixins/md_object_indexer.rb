# encoding: UTF-8

module GoodData
  module Mixin
    module MdObjectIndexer
      MD_OBJ_CTG = 'obj'

      # Returns either list of objects or a specific object. This method is reimplemented in subclasses to leverage specific implementation for specific type of objects. Options is used in subclasses specifically to provide shorthand for getting a full objects after getting a list of hashes from query resource
      # @param [Object] id id can be either a number a String (as a URI). Subclasses should also be abel to deal with getting the instance of MdObject already and a :all symbol
      # @param [Hash] options the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [MdObject] if id is a String or number single object is returned
      # @return [Array] if :all was provided as an id, list of objects should be returned. Note that this is implemented only in the subclasses. MdObject does not support this since API has no means to return list of all types of objects
      def [](id, options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, :client => client]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        fail "You have to provide an \"id\" to be searched for." unless id
        fail(NoProjectError, 'Connect to a project before searching for an object') unless project
        return all(options) if id == :all
        return id if id.is_a?(MdObject)
        uri = if id.is_a?(Integer) || id =~ /^\d+$/
                "#{project.md[MD_OBJ_CTG]}/#{id}"
              elsif id !~ /\//
                identifier_to_uri options, id
              elsif id =~ /^\//
                id
              else
                fail 'Unexpected object id format: expected numeric ID, identifier with no slashes or an URI starting with a slash'
              end
        # new(GoodData.get uri) unless uri.nil?
        if uri # rubocop:disable Style/GuardClause
          raw = client.get(uri)
          md_class = self
          case raw.keys.first
          when 'attribute'
            md_class = GoodData::Attribute
          when 'report'
            md_class = GoodData::Report
          when 'reportDefinition'
            md_class = GoodData::ReportDefinition
          else
            md_class = self
          end

          client.create(md_class, raw, client: client, project: project)
        end
      end

      alias_method :get_by_id, :[]
    end
  end
end
