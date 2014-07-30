# encoding: UTF-8

require_relative '../core/connection'
require_relative '../core/project'

require_relative '../mixins/content_getter'
require_relative '../mixins/data_getter'
require_relative '../mixins/links'
require_relative '../mixins/md_finders'
require_relative '../mixins/md_json'
require_relative '../mixins/md_object_indexer'
require_relative '../mixins/md_object_query'
require_relative '../mixins/md_relations'
require_relative '../mixins/meta_getter'
require_relative '../mixins/meta_property_reader'
require_relative '../mixins/meta_property_writer'
require_relative '../mixins/not_attribute'
require_relative '../mixins/not_exportable'
require_relative '../mixins/not_fact'
require_relative '../mixins/not_metric'
require_relative '../mixins/not_label'
require_relative '../mixins/obj_id'
require_relative '../mixins/root_key_getter'
require_relative '../mixins/root_key_setter'
require_relative '../mixins/timestamps'

module GoodData
  class MdObject
    IDENTIFIERS_CFG = 'instance-identifiers'

    attr_reader :json

    alias_method :raw_data, :json
    alias_method :to_hash, :json

    include GoodData::Mixin::RootKeyGetter

    include GoodData::Mixin::MdJson

    include GoodData::Mixin::DataGetter

    include GoodData::Mixin::MetaGetter

    include GoodData::Mixin::ContentGetter

    include GoodData::Mixin::Timestamps

    include GoodData::Mixin::Links

    include GoodData::Mixin::ObjId

    include GoodData::Mixin::NotAttribute

    include GoodData::Mixin::NotExportable

    include GoodData::Mixin::NotFact

    include GoodData::Mixin::NotMetric

    include GoodData::Mixin::NotLabel

    include GoodData::Mixin::MdRelations

    class << self
      include GoodData::Mixin::RootKeySetter

      include GoodData::Mixin::MetaPropertyReader

      include GoodData::Mixin::MetaPropertyWriter

      include GoodData::Mixin::MdObjectQuery

      include GoodData::Mixin::MdObjectIndexer

      include GoodData::Mixin::MdFinders

      # TODO: Add test
      def identifier_to_uri(*ids)
        fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
        uri = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, 'identifierToUri' => ids
        if response['identifiers'].empty?
          nil
        else
          identifiers = response['identifiers']
          ids_lookup = identifiers.reduce({}) do |a, e|
            a[e['identifier']] = e['uri']
            a
          end
          uris = ids.map { |x| ids_lookup[x] }
          uris.count == 1 ? uris.first : uris
        end
      end

      alias_method :id_to_uri, :identifier_to_uri

      alias_method :get_by_id, :[]
    end

    metadata_property_reader :uri, :identifier, :title, :summary, :tags, :deprecated, :category
    metadata_property_writer :tags, :summary, :title, :identifier

    def initialize(data)
      @json = data.to_hash
    end

    def delete
      if saved?
        GoodData.delete(uri)
        meta.delete('uri')
        # ["uri"] = nil
      end
    end

    def reload!
      @json = GoodData.get(uri) if saved?
      self
    end

    alias_method :refresh, :reload!

    def browser_uri
      GoodData.connection.url + meta['uri']
    end

    def deprecated=(flag)
      if flag == '1' || flag == 1
        meta['deprecated'] = '1'
      elsif flag == '0' || flag == 0
        meta['deprecated'] = '0'
      else
        fail 'You have to provide flag as either 1 or "1" or 0 or "0"'
      end
    end

    def project
      @project ||= Project[uri.gsub(%r{\/obj\/\d+$}, '')]
    end

    def saved?
      res = uri.nil?
      !res
    end

    def save
      fail('Validation failed') unless validate

      if saved?
        GoodData.put(uri, to_json)
      else
        explicit_identifier = meta['identifier']
        # Pre-check to provide a user-friendly error rather than
        # failing later
        if explicit_identifier && MdObject[explicit_identifier]
          fail "Identifier '#{explicit_identifier}' already in use"
        end
        result = GoodData.post(GoodData.project.md['obj'], to_json)
        saved_object = self.class[result['uri']]
        # TODO: add test for explicitly provided identifier

        @json = saved_object.raw_data
        if explicit_identifier
          # Object creation API discards the identifier. If an identifier
          # was explicitely provided in the origina object, we need to set
          # it explicitly with an extra PUT call.
          meta['identifier'] = explicit_identifier
          begin
            GoodData.put(uri, to_json)
          rescue => e
            # Cannot change the identifier (perhaps because it's in use
            # already?), cleaning up.
            GoodData.delete(uri)
            raise e
          end
        end
      end
      self
    end

    # Saves an object with a different name
    #
    # @param new_title [String] New title. If not provided one is provided
    # @return [GoodData::MdObject] MdObject that has been saved as
    def save_as(new_title = "Clone of #{title}")
      dupped = Marshal.load(Marshal.dump(raw_data))
      dupped[root_key]['meta'].delete('uri')
      dupped[root_key]['meta'].delete('identifier')
      dupped[root_key]['meta']['title'] = new_title
      x = self.class.new(dupped)
      x.save
    end

    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end

    def validate
      true
    end

    alias_method :display_form?, :label?
  end
end
