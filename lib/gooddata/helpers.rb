# encoding: UTF-8

require 'active_support/inflections'

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

      def find_goodfile(pwd=`pwd`.strip!, options={})
        root = Pathname(options[:root] || '/')
        pwd = Pathname(pwd).expand_path
        begin
          gf = pwd + 'Goodfile'
          if gf.exist?
            return gf
          end
          pwd = pwd.parent
        end until root == pwd
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

      def sanitize_string(str)
        str = ActiveSupport::Inflector.transliterate(str).downcase
        str.gsub(/[^a-z]/, '')
      end
    end
  end
end
