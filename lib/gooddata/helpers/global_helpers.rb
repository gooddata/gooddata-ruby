# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'base64'
require 'pathname'
require 'hashie'
require 'openssl'

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

      # It takes what should be mapped to what and creates a mapping that is suitable for other internal methods.
      # This means looking up the objects and returning it as array of pairs.
      # The input can be given in several ways
      #
      # 1. Hash. For example it could look like
      # {'label.states.name' => 'label.state.id'}
      #
      # 2 Arrays. In such case the arrays are zipped together. First item will be swapped for the first item in the second array etc.
      # ['label.states.name'], ['label.state.id']
      #
      # @param what [Hash | Array] List/Hash of objects to be swapped
      # @param for_what [Array] List of objects to be swapped
      # @return [Array<GoodData::MdObject>] List of pairs of objects
      def prepare_mapping(what, for_what = nil, options = {})
        project = options[:project] || (for_what.is_a?(Hash) && for_what[:project]) || fail('Project has to be provided')
        mapping = if what.is_a?(Hash)
                    whats = what.keys
                    to_whats = what.values
                    whats.zip(to_whats)
                  elsif what.is_a?(Array) && for_what.is_a?(Array)
                    whats.zip(to_whats)
                  else
                    [[what, for_what]]
                  end
        mapping.pmap { |f, t| [project.objects(f), project.objects(t)] }
      end

      def get_path(an_object, path = [])
        return an_object if path.empty?
        path.reduce(an_object) do |a, e|
          a && a.key?(e) ? a[e] : nil
        end
      end

      def last_uri_part(uri)
        uri.split('/').last
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
        titleized = str.gsub(/[\.|_](.)/, &:upcase)
        titleized = titleized.tr('_', ' ')
        titleized[0] = titleized[0].upcase
        titleized
      end

      def join(master, slave, on, on2, options = {})
        full_outer = options[:full_outer]
        inner = options[:inner]

        lookup = create_lookup(slave, on2)
        marked_lookup = {}
        results = master.reduce([]) do |a, line|
          matching_values = lookup[line.values_at(*on)] || []
          marked_lookup[line.values_at(*on)] = 1
          if matching_values.empty? && !inner
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

      def interpolate_error_messages(errors)
        errors.map { |e| interpolate_error_message(e) }
      end

      def interpolate_error_message(error)
        message = error['error']['message']
        params = error['error']['parameters']
        sprintf(message, *params)
      end

      def transform_keys!(an_object)
        return enum_for(:transform_keys!) unless block_given?
        an_object.keys.each do |key|
          an_object[yield(key)] = an_object.delete(key)
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
        transform_keys(an_object, &:to_s)
      end

      def deep_stringify_keys(an_object)
        deep_transform_keys(an_object, &:to_s)
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

      def parse_http_exception(e)
        JSON.parse(e.response)
      end

      # Creates a matrix with zeroes in all places. It is implemented as an Array of Arrays. First rows then columns.
      #
      # @param [Integer] m Number of rows
      # @param [Integer] n Number of cols
      # @param [Integer] val Alternatively can fill in positions with different values than zeroes. Defualt is zero.
      # @return [Array<Array>] Returns a matrix of zeroes
      def zeroes(m, n, val = 0)
        m.times.map { n.times.map { val } }
      end

      # encrypts data with the given key. returns a binary data with the
      # unhashed random iv in the first 16 bytes
      def encrypt(data, key)
        cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
        cipher.encrypt
        cipher.key = key = Digest::SHA256.digest(key)
        random_iv = cipher.random_iv
        cipher.iv = Digest::SHA256.digest(random_iv + key)[0..15]
        encrypted = cipher.update(data)
        encrypted << cipher.final
        # add unhashed iv to front of encrypted data

        Base64.encode64(random_iv + encrypted)
      end

      def decrypt(data_base_64, key)
        return '' if key.nil? || key.empty?

        data = Base64.decode64(data_base_64)

        cipher = OpenSSL::Cipher::Cipher.new('aes-256-cbc')
        cipher.decrypt
        cipher.key = cipher_key = Digest::SHA256.digest(key)
        random_iv = data[0..15] # extract iv from first 16 bytes
        data = data[16..data.size - 1]
        cipher.iv = Digest::SHA256.digest(random_iv + cipher_key)[0..15]
        begin
          decrypted = cipher.update(data)
          decrypted << cipher.final
        rescue
          puts 'Error'
          return nil
        end

        puts "DECRYPTED: #{decrypted}"
        decrypted
      end
    end
  end

  class << self
    def get_client(opts)
      client = opts[:client]
      fail ArgumentError, 'No :client specified' if client.nil?

      client
    end

    def get_client_and_project(opts)
      client = opts[:client]
      fail ArgumentError, 'No :client specified' if client.nil?

      p = opts[:project]
      fail ArgumentError, 'No :project specified' if p.nil?

      project = GoodData::Project[p, opts]
      fail ArgumentError, 'Wrong :project specified' if project.nil?

      [client, project]
    end
  end
end
