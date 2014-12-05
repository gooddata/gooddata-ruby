# encoding: UTF-8

require 'active_support/all'
require 'pathname'

module GoodData
  module Helpers
    class << self
      def home_directory
        running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
      end

      def running_on_windows?
        RUBY_PLATFORM =~ /mswin32|mingw32/
      end

      def running_on_a_mac?
        RUBY_PLATFORM =~ /-darwin\d/
      end

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
        key = hidden ? ENCODED_PARAMS_KEY : ENCODED_HIDDEN_PARAMS_KEY
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

      def error(msg)
        STDERR.puts(msg)
        exit 1
      end

      # FIXME: Windows incompatible
      def find_goodfile(pwd = `pwd`.strip!, options = {})
        root = Pathname(options[:root] || '/')
        pwd = Pathname(pwd).expand_path
        loop do
          gf = pwd + 'Goodfile'
          return gf if gf.exist?
          pwd = pwd.parent
          break unless root == pwd
        end
        nil
      end

      def get_path(an_object, path = [])
        return an_object if path.empty?
        path.reduce(an_object) do |a, e|
          a && a.key?(e) ? a[e] : nil
        end
      end

      def hash_dfs(thing, &block)
        if !thing.is_a?(Hash) && !thing.is_a?(Array) # rubocop:disable Style/GuardClause
        elsif thing.is_a?(Array)
          thing.each do |child|
            hash_dfs(child, &block)
          end
        else
          thing.each do |key, val|
            yield(thing, key)
            hash_dfs(val, &block)
          end
        end
      end

      # TODO: Implement without using ActiveSupport
      def sanitize_string(str, filter = /[^a-z_]/, replacement = '')
        str = ActiveSupport::Inflector.transliterate(str).downcase
        str.gsub(filter, replacement)
      end

      # TODO: Implement without using ActiveSupport
      def humanize(str)
        ActiveSupport::Inflector.humanize(str)
      end

      def underline(x)
        '=' * x.size
      end

      # Recurscively changes the string keys of a hash to symbols.
      #
      # @param h [Hash] Data structure to change
      # @return [Hash] Hash with symbolized keys
      def symbolize_keys_deep!(h)
        if Hash == h
          Hash[
            h.map do |k, v|
              [k.respond_to?(:to_sym) ? k.to_sym : k, symbolize_keys_deep!(v)]
            end
          ]
        else
          h
        end
      end
    end
  end
end
