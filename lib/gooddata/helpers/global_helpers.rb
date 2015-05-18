# encoding: UTF-8

require 'active_support/all'
require 'pathname'

require_relative 'global_helpers_params'

module GoodData
  module Helpers
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

      # TODO: Implement without using ActiveSupport
      def humanize(str)
        ActiveSupport::Inflector.humanize(str)
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

      # TODO: Implement without using ActiveSupport
      def sanitize_string(str, filter = /[^a-z_]/, replacement = '')
        str = ActiveSupport::Inflector.transliterate(str).downcase
        str.gsub(filter, replacement)
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

      def stringify_keys_deep!(h)
        if Hash == h.class
          Hash[
            h.map do |k, v|
              [k.respond_to?(:to_s) ? k.to_s : k, stringify_keys_deep!(v)]
            end
          ]
        else
          h
        end
      end
    end
  end
end
