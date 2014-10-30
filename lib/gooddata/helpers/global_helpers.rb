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

      def hash_dfs(thing, &block)
        if !thing.is_a?(Hash) && !thing.is_a?(Array)
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
