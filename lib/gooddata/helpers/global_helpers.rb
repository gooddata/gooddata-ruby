# encoding: UTF-8

require 'pathname'
require 'hashie'

require_relative 'global_helpers_params'

module GoodData
  module Helpers
    class DeepMergeableHash < Hash
      include Hashie::Extensions::DeepMerge
    end

    class << self
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

      def home_directory
        running_on_windows? ? ENV['USERPROFILE'] : ENV['HOME']
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

      def titleize(str)
        titleized = str.gsub(/[\.|_](.)/) { |x| x.upcase }
        titleized = titleized.gsub('_', ' ')
        titleized[0] = titleized[0].upcase
        titleized
      end

      def join(master, slave, on, on2, options = {})
        full_outer = options[:full_outer]

        lookup = create_lookup(slave, on2)
        marked_lookup = {}
        results = master.reduce([]) do |a, line|
          matching_values = lookup[line.values_at(*on)] || []
          marked_lookup[line.values_at(*on)] = 1
          if matching_values.empty?
            a << line.to_hash
          else
            matching_values.each do |matching_value|
              a << matching_value.to_hash.merge(line.to_hash)
            end
          end
          a
        end

        if full_outer
          (lookup.keys - marked_lookup.keys).each do |key|
            puts lookup[key]
            results << lookup[key].first.to_hash
          end
        end
        results
      end

      def running_on_windows?
        RUBY_PLATFORM =~ /mswin32|mingw32/
      end

      def running_on_a_mac?
        RUBY_PLATFORM =~ /-darwin\d/
      end

      def underline(x)
        '=' * x.size
      end

      def transform_keys!(an_object)
        return enum_for(:transform_keys!) unless block_given?
        an_object.keys.each do |key|
          an_object[yield(key)] = delete(key)
        end
        an_object
      end

      def symbolize_keys!(an_object)
        transform_keys!(an_object) do |key|
          begin
            key.to_sym
          rescue
            key
          end
        end
      end

      def symbolize_keys(an_object)
        transform_keys(an_object) do |key|
          begin
            key.to_sym
          rescue
            key
          end
        end
      end

      def transform_keys(an_object)
        return enum_for(:transform_keys) unless block_given?
        result = an_object.class.new
        an_object.each_key do |key|
          result[yield(key)] = an_object[key]
        end
        result
      end

      def deep_symbolize_keys(an_object)
        deep_transform_keys(an_object) do |key|
          begin
            key.to_sym
          rescue
            key
          end
        end
      end

      def stringify_keys(an_object)
        transform_keys(an_object) { |key| key.to_s }
      end

      def deep_stringify_keys(an_object)
        deep_transform_keys(an_object) { |key| key.to_s }
      end

      def deep_transform_keys(an_object, &block)
        _deep_transform_keys_in_object(an_object, &block)
      end

      def _deep_transform_keys_in_object(object, &block)
        case object
        when Hash
          object.each_with_object({}) do |(key, value), result|
            result[yield(key)] = _deep_transform_keys_in_object(value, &block)
          end
        when Array
          object.map { |e| _deep_transform_keys_in_object(e, &block) }
        else
          object
        end
      end

      def deep_dup(an_object)
        case an_object
        when Array
          an_object.map { |it| GoodData::Helpers.deep_dup(it) }
        when Hash
          an_object.each_with_object(an_object.dup) do |(key, value), hash|
            hash[GoodData::Helpers.deep_dup(key)] = GoodData::Helpers.deep_dup(value)
          end
        when Object
          an_object.duplicable? ? an_object.dup : an_object
        end
      end

      def undot(params)
        # for each key-value config given
        params.map do |k, v|
          # dot notation to hash
          k.split('__').reverse.reduce(v) do |memo, obj|
            GoodData::Helper.DeepMergeableHash[{ obj => memo }]
          end
        end
      end
    end
  end
end
