# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Helpers
    ENCODED_PARAMS_KEY = 'gd_encoded_params'
    ENCODED_HIDDEN_PARAMS_KEY = 'gd_encoded_hidden_params'

    class << self
      # Encodes parameters for passing them to GD execution platform.
      # Core types are kept and complex types (arrays, structures, etc) are
      # JSON encoded into key hash "gd_encoded_params" or
      # "gd_encoded_hidden_params", depending on the 'hidden' method param.
      # The two different keys are used because the params and hidden params
      # are merged by the platform and if we use the same key,
      # the param would be overwritten.
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
      def encode_params(params, data_key)
        res = {}
        nested = {}
        core_types = [FalseClass, Integer, Float, NilClass, TrueClass, String]
        params.each do |k, v|
          if core_types.include?(v.class)
            res[k] = v
          else
            nested[k] = v
          end
        end
        res[data_key] = nested.to_json unless nested.empty?
        res
      end

      # Encodes public parameters for passing them to GD execution platform.
      # @param [Hash] params Parameters to be encoded
      # @return [Hash] Encoded parameters
      def encode_public_params(params)
        encode_params(params, ENCODED_PARAMS_KEY)
      end

      # Encodes hidden parameters for passing them to GD execution platform.
      # @param [Hash] params Parameters to be encoded
      # @return [Hash] Encoded parameters
      def encode_hidden_params(params)
        encode_params(params, ENCODED_HIDDEN_PARAMS_KEY)
      end

      # Decodes params as they came from the platform.
      # @params Parameter hash need to be decoded
      # @option options [Boolean] :resolve_reference_params Resolve reference parameters in gd_encoded_params or not
      # @return [Hash] Decoded parameters
      def decode_params(params, options = {})
        key = ENCODED_PARAMS_KEY.to_s
        hidden_key = ENCODED_HIDDEN_PARAMS_KEY.to_s
        data_params = params[key] || '{}'
        hidden_data_params = if params.key?(hidden_key) && params[hidden_key].nil?
                               "{\"#{hidden_key}\" : null}"
                             elsif params.key?(hidden_key)
                               params[hidden_key]
                             else
                               '{}'
                             end

        reference_values = []
        # Replace reference parameters by the actual values. Use backslash to escape a reference parameter, e.g: \${not_a_param},
        # the ${not_a_param} will not be replaced
        if options[:resolve_reference_params]
          data_params, reference_values = resolve_reference_params(data_params, params)
          hidden_data_params, = resolve_reference_params(hidden_data_params, params)
        end

        begin
          parsed_data_params = data_params.is_a?(Hash) ? data_params : JSON.parse(data_params)
        rescue JSON::ParserError => exception
          reason = exception.message
          reference_values.each { |secret_value| reason.gsub!("\"#{secret_value}\"", '"***"') }
          raise exception.class, "Error reading json from '#{key}', reason: #{reason}"
        end

        begin
          parsed_hidden_data_params = hidden_data_params.is_a?(Hash) ? hidden_data_params : JSON.parse(hidden_data_params)
        rescue JSON::ParserError => exception
          raise exception.class, "Error reading json from '#{hidden_key}'"
        end

        # Add the nil on ENCODED_HIDDEN_PARAMS_KEY
        # if the data was retrieved from API You will not have the actual values so encode -> decode is not losless. The nil on the key prevents the server from deleting the key
        parsed_hidden_data_params[ENCODED_HIDDEN_PARAMS_KEY] = nil unless parsed_hidden_data_params.empty?

        params.delete(key)
        params.delete(hidden_key)
        params = params.deep_merge(parsed_data_params).deep_merge(parsed_hidden_data_params)

        if options[:convert_pipe_delimited_params]
          convert_pipe_delimited_params = lambda do |args|
            args = args.select { |k, _| k.include? "|" }
            lines = args.keys.map do |k|
              hash = {}
              last_a = nil
              last_e = nil
              k.split("|").reduce(hash) do |a, e|
                last_a = a
                last_e = e
                a[e] = {}
              end
              last_a[last_e] = args[k]
              hash
            end

            lines.reduce({}) do |a, e|
              a.deep_merge(e)
            end
          end

          pipe_delimited_params = convert_pipe_delimited_params.call(params)
          params.delete_if do |k, _|
            k.include?('|')
          end
          params = params.deep_merge(pipe_delimited_params)
        end

        params
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

      def stringify_values(value)
        case value
        when nil
          value
        when Hash
          Hash[
            value.map do |k, v|
              [k, stringify_values(v)]
            end
          ]
        when Array
          value.map do |v|
            stringify_values(v)
          end
        else
          value.to_s
        end
      end

      private

      def resolve_reference_params(data_params, params)
        reference_values = []
        regexps = Regexp.union(/\\\\/, /\\\$/, /\$\{(\w+)\}/)
        resolve_reference = lambda do |v|
          if v.is_a? Hash
            Hash[
              v.map do |k, v2|
                [k, resolve_reference.call(v2)]
              end
            ]
          elsif v.is_a? Array
            v.map do |v2|
              resolve_reference.call(v2)
            end
          elsif !v.is_a?(String)
            v
          else
            v.gsub(regexps) do |match|
              if match =~ /\\\\/
                data_params.is_a?(Hash) ? '\\' : '\\\\' # rubocop: disable Metrics/BlockNesting
              elsif match =~ /\\\$/
                '$'
              elsif match =~ /\$\{(\w+)\}/
                val = params["#{$1}"] || raise("The gd_encoded_params parameter contains unknow reference #{$1}") # rubocop: disable Style/PerlBackrefs
                reference_values << val
                val
              end
            end
          end
        end

        data_params = if data_params.is_a? Hash
                        Hash[data_params.map do |k, v|
                          [k, resolve_reference.call(v)]
                        end]
                      else
                        resolve_reference.call(data_params)
                      end

        [data_params, reference_values]
      end
    end
  end
end
