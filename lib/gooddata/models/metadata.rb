# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'multi_json'

require_relative '../core/project'

require_relative '../mixins/mixins'
require_relative '../rest/object'

module GoodData
  class MdObject < Rest::Resource
    MD_OBJ_CTG = 'obj'
    IDENTIFIERS_CFG = 'instance-identifiers'

    extend Mixin::MdIdToUri
    extend Mixin::MdObjectIndexer
    extend Mixin::MdObjectQuery

    extend Mixin::MdFinders
    extend Mixin::MdObjId

    include Mixin::Links
    include Mixin::ObjId
    include Mixin::MdRelations
    include Mixin::MdGrantees

    class << self
      # Method used for replacing objects like Attribute, Fact or Metric. It takes the object. Scans its JSON
      # representation and returns a new one with object references changed according to mapping. The references an be found either in the object structure or in the MAQL in bracketed form. This implementation takes care only of those in bracketed form.
      #
      # @param obj [GoodData::MdObject] what Object that should be replaced
      # @param mapping [Array[Array]] Array of mapping pairs.
      # @return [GoodData::MdObject]
      def replace_bracketed(obj, mapping)
        replace(obj, mapping) { |e, a, b| e.gsub("[#{a}]", "[#{b}]") }
      end

      # Method used for replacing objects like Attribute, Fact or Metric. It takes the object. Scans its JSON
      # representation and returns a new one with object references changed according to mapping. The references an be found either in the object structure or in the MAQL in bracketed form. This implementation takes care only of those in object structure where they are as a string in JSON.
      #
      # @param obj [GoodData::MdObject] Object that should be replaced
      # @param mapping [Array[Array]] Array of mapping pairs.
      # @return [GoodData::MdObject]
      def replace_quoted(obj, mapping)
        replace(obj, mapping) do |e, a, b|
          e.gsub("\"#{a}\"", "\"#{b}\"")
        end
      end

      # Helper method used for replacing objects like Attribute, Fact or Metric. It takes the object. Scans its JSON
      # representation yields for a client to perform replacement for each mapping pair and returns a new one
      # with object of the same type as obj.
      #
      # @param obj [GoodData::MdObject] Object that should be replaced
      # @param mapping [Array[Array]] Array of mapping pairs.
      # @param block [Proc] Block that receives the object state as a JSON string and mapping pair and expects a new object state as a JSON string back
      # @return [GoodData::MdObject]
      def replace(obj, mapping, &block)
        json = mapping.reduce(obj.to_json) do |a, e|
          obj_a, obj_b = e
          uri_what = obj_a.respond_to?(:uri) ? obj_a.uri : obj_a
          uri_for_what = obj_b.respond_to?(:uri) ? obj_b.uri : obj_b
          block.call(a, uri_what, uri_for_what)
        end
        client = obj.client
        client.create(obj.class, MultiJson.load(json), :project => obj.project)
      end

      # Helper method used for finding attribute elements that are interesting becuase they can be possibly
      # replaced according to mapping specification. This walks through all the attribute elemets. Picks only those
      # whose attribute is mentioned in the mapping. Walks through all the labels of that particular attribute and
      # tries to find a value from one to be translated into a label in second. Obviously this is not guaranteed to
      # find any results or in some cases can yield to incorrect results.
      #
      # @param obj [GoodData::MdObject] Object that should be replaced
      # @param mapping [Array[Array]] Array of mapping pairs.
      # @param block [Proc] Block that receives the object state as a JSON string and mapping pair and expects a new object state as a JSON string back
      # @return [GoodData::MdObject]
      def find_replaceable_values(obj, mapping)
        values_to_replace = GoodData::SmallGoodZilla.extract_element_uri_pairs(MultiJson.dump(obj.to_json))
        values_from_mapping = values_to_replace.select { |i| mapping.map { |a, _| a.uri }.include?(i.first) }
        replaceable_vals = values_from_mapping.map do |a_uri, id|
          from_attribute, to_attribute = mapping.find { |k, _| k.uri == a_uri }
          vals = from_attribute.values_for(id)
          labels = to_attribute.labels
          results = labels.to_enum.mapcat do |l|
            vals.map do |v|
              begin
                l.find_value_uri(v)
              rescue
                nil
              end
            end
          end
          fail "Unable to find replacement for #{a_uri}" if results.compact.empty?
          [a_uri, id, results.compact.first]
        end
        replaceable_vals.map { |a, id, r| ["#{a}/elements?id=#{id}", r] }
      end
    end

    metadata_property_reader :uri, :identifier, :title, :summary, :tags, :category
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

    def deprecated
      if meta['deprecated'] == '1'
        true
      else
        false
      end
    end
    alias_method :deprecated?, :deprecated

    def deprecated=(flag)
      if flag == '1' || flag == 1 || flag == true
        meta['deprecated'] = '1'
      elsif flag == '0' || flag == 0 || flag == false
        meta['deprecated'] = '0'
      else
        fail 'You have to provide flag as either 1 or "1" or 0 or "0" or true/false'
      end
    end

    def project
      @project ||= Project[uri.gsub(%r{\/obj\/\d+$}, ''), :client => client]
    end

    # Method used for replacing objects like Attribute, Fact or Metric. Returns new object of the same type.
    #
    # @param [GoodData::MdObject] what Object that should be replaced
    # @param [GoodData::MdObject] for_what Object it is replaced with
    # @return [GoodData::Metric]
    def replace(mapping)
      GoodData::MdObject.replace_quoted(self, mapping)
    end

    # Method used for replacing objects like Attribute, Fact or Metric. Returns itself mutated.
    # @param [GoodData::MdObject] what Object that should be replaced
    # @param [GoodData::MdObject] for_what Object it is replaced with
    # @return [GoodData::Metric]
    def replace!(mapping)
      x = replace(mapping)
      @json = x.json
      self
    end

    def remove_tag(a_tag)
      self.tags = tag_set.delete(a_tag).to_a.join(' ')
      self
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

    def listed?
      !unlisted?
    end

    def unlisted
      meta['unlisted'] == '1'
    end
    alias_method :unlisted?, :unlisted

    def unlisted=(flag)
      if flag == true
        meta['unlisted'] = '1'
      elsif flag == false
        meta['unlisted'] = '0'
      else
        fail 'You have to provide flag as either true or false'
      end
    end

    def validate
      true
    end
  end
end
