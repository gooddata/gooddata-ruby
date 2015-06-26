# encoding: UTF-8

require_relative '../core/project'

require_relative '../mixins/mixins'
require_relative '../rest/object'

module GoodData
  class MdObject < GoodData::Rest::Object
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    attr_reader :json

    alias_method :raw_data, :json
    alias_method :to_hash, :json

    include GoodData::Mixin::RestResource

    class << self
      def metadata_property_reader(*props)
        props.each do |prop|
          define_method prop, proc { meta[prop.to_s] }
        end
      end

      def metadata_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| meta[prop.to_s] = val }
        end
      end
    end

    metadata_property_reader :uri, :identifier, :title, :summary, :tags, :deprecated, :category
    metadata_property_writer :tags, :summary, :title, :identifier

    def initialize(data)
      @json = data.to_hash
    end

    def add_tag(a_tag)
      self.tags = tag_set.add(a_tag).to_a.join(' ')
      self
    end

    def delete
      if saved? # rubocop:disable Style/GuardClause
        client.delete(uri)
        meta.delete('uri')
      end
    end

    def reload!
      @json = client.get(uri) if saved?
      self
    end

    alias_method :refresh, :reload!

    def browser_uri
      client.connection.server_url + meta['uri']
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
      @project ||= Project[uri.gsub(%r{\/obj\/\d+$}, ''), :client => client]
    end

    def remove_tag(a_tag)
      self.tags = tag_set.delete(a_tag).to_a.join(' ')
      self
    end

    def saved?
      res = uri.nil?
      !res
    end

    def save
      fail('Validation failed') unless validate

      opts = {
        :client => client,
        :project => project
      }

      if saved?
        client.put(uri, to_json)
      else
        explicit_identifier = meta['identifier']
        # Pre-check to provide a user-friendly error rather than
        # failing later
        if explicit_identifier && MdObject[explicit_identifier, opts]
          fail "Identifier '#{explicit_identifier}' already in use"
        end

        req_uri = project.md['obj']
        result = client.post(req_uri, to_json)
        saved_object = self.class[result['uri'], opts]
        # TODO: add test for explicitly provided identifier

        @json = saved_object.json
        if explicit_identifier
          # Object creation API discards the identifier. If an identifier
          # was explicitely provided in the origina object, we need to set
          # it explicitly with an extra PUT call.
          meta['identifier'] = explicit_identifier
          begin
            client.put(uri, to_json)
          rescue => e
            # Cannot change the identifier (perhaps because it's in use
            # already?), cleaning up.
            client.delete(uri)
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
    def save_as(new_title = nil)
      new_title = "Clone of #{title}" if new_title.nil?

      dupped = Marshal.load(Marshal.dump(json))
      dupped[root_key]['meta'].delete('uri')
      dupped[root_key]['meta'].delete('identifier')
      dupped[root_key]['meta']['title'] = new_title
      x = client.create(self.class, dupped, :project => project)
      x.save
    end

    def tag_set
      tags.scan(/\w+/).to_set
    end

    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end

    def validate
      true
    end
  end
end
