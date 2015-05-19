# encoding: UTF-8

module GoodData
  module Helpers
    class << self
      ENCODED_PARAMS_KEY = :gd_encoded_params
      ENCODED_HIDDEN_PARAMS_KEY = :gd_encoded_hidden_params

      # Encodes parameters for passing them to GD execution platform.
      # Core types are kept and complex types (arrays, structures, etc) are JSON encoded into key hash "gd_encoded_params" or "gd_encoded_hidden_params", depending on the 'hidden' method param.
      # The two different keys are used because the params and hidden params are merged by the platform and if we use the same key, the param would be overwritten.
      #
      # Core types are following:
      # - Boolean (true, false)
      # - Fixnum
      # - Float
      # - Nil
      # - String
      #
      # @param [Hash] params Parameters to be encoded
      # @return [Hash] Encoded parameters
      def encode_params(params, hidden = false)
        res = {}
        nested = {}
        core_types = [FalseClass, Fixnum, Float, NilClass, TrueClass, String]
        params.each do |k, v|
          if core_types.include?(v.class)
            res[k] = v
          else
            nested[k] = v
          end
        end
        key = hidden ? ENCODED_HIDDEN_PARAMS_KEY : ENCODED_PARAMS_KEY
        res[key] = nested.to_json unless nested.empty?
        res
      end

      # Decodes params as they came from the platform
      # The "data" key is supposed to be json and it's parsed - if this
      def decode_params(params)
        key = ENCODED_PARAMS_KEY.to_s
        hidden_key = ENCODED_HIDDEN_PARAMS_KEY.to_s
        data_params = params[key] || '{}'
        hidden_data_params = params[hidden_key] || '{}'

        begin
          parsed_data_params = JSON.parse(data_params)
          parsed_hidden_data_params = JSON.parse(hidden_data_params)
        rescue JSON::ParserError => e
          raise e.class, "Error reading json from '#{key}' or '#{hidden_key}' in params #{params}\n #{e.message}"
        end
        params.delete(key)
        params.delete(hidden_key)
        params.merge(parsed_data_params).merge(parsed_hidden_data_params)
      end

      # A helper which allows you to diff two lists of objects. The objects
      # can be arbitrary objects as long as they respond to to_hash because
      # the diff is eventually done on hashes. It allows you to specify
      # several options to allow you to limit on what the sameness test is done
      #
      # @param [Array<Object>] old_list List of objects that serves as a base for comparison
      # @param [Array<Object>] new_list List of objects that is compared agianst the old_list
      # @return [Hash] A structure that contains the result of the comparison. There are
      # four keys.
      # :added contains the list that are in new_list but were not in the old_list
      # :added contains the list that are in old_list but were not in the new_list
      # :same contains objects that are in both lists and they are the same
      # :changed contains list of objects that changed along ith original, the new one
      # and the list of changes
      def diff(old_list, new_list, options = {})
        old_list = old_list.map(&:to_hash)
        new_list = new_list.map(&:to_hash)

        fields = options[:fields]
        lookup_key = options[:key]

        old_lookup = Hash[old_list.map { |v| [v[lookup_key], v] }]

        res = {
          :added => [],
          :removed => [],
          :changed => [],
          :same => []
        }

        new_list.each do |new_obj|
          old_obj = old_lookup[new_obj[lookup_key]]
          if old_obj.nil?
            res[:added] << new_obj
            next
          end

          if fields
            sliced_old_obj = old_obj.slice(*fields)
            sliced_new_obj = new_obj.slice(*fields)
          else
            sliced_old_obj = old_obj
            sliced_new_obj = new_obj
          end
          if sliced_old_obj != sliced_new_obj
            difference = sliced_new_obj.to_a - sliced_old_obj.to_a
            differences = Hash[*difference.mapcat { |x| x }]
            res[:changed] << {
              old_obj: old_obj,
              new_obj: new_obj,
              diff: differences
            }
          else
            res[:same] << old_obj
          end
        end

        new_lookup = Hash[new_list.map { |v| [v[lookup_key], v] }]
        old_list.each do |old_obj|
          new_obj = new_lookup[old_obj[lookup_key]]
          if new_obj.nil?
            res[:removed] << old_obj
            next
          end
        end

        res
      end

      def create_lookup(collection, on)
        lookup = {}
        if on.is_a?(Array)
          collection.each do |e|
            key = e.values_at(*on)
            lookup[key] = [] unless lookup.key?(key)
            lookup[key] << e
          end
        else
          collection.each do |e|
            key = e[on]
            lookup[key] = [] unless lookup.key?(key)
            lookup[key] << e
          end
        end
        lookup
      end
    end
  end
end
