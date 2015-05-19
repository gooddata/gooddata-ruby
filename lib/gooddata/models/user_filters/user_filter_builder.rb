# encoding: UTF-8

require_relative 'user_filter_builder_create'
require_relative 'user_filter_builder_execute'

module GoodData
  module UserFilterBuilder
    # Main Entry function. Gets values and processes them to get filters
    # that are suitable for other function to process.
    # Values can be read from file or provided inline as an array.
    # The results are then preprocessed. It is possible to provide
    # multiple values for an attribute tries to deduplicate the values if
    # they are not unique. Allows for setting over/to filters and allows for
    # setting up filters from multiple columns. It is specially designed so many
    # aspects of configuration are modifiable so you do have to preprocess the
    # data as little as possible ideally you should be able to use data that
    # came directly from the source system and that are intended for use in
    # other parts of ETL.
    #
    # @param options [Hash]
    # @return [Boolean]
    def self.get_filters(file, options = {})
      values = get_values(file, options)
      reduce_results(values)
    end

    # Function that tells you if the file should be read line_wise. This happens
    # if you have only one label defined and you do not have columns specified
    #
    # @param options [Hash]
    # @return [Boolean]
    def self.row_based?(options = {})
      options[:labels].count == 1 && !options[:labels].first.key?(:column)
    end

    def self.read_file(file, options = {})
      memo = {}
      params = row_based?(options) ? { headers: false } : { headers: true }

      CSV.foreach(file, params.merge(return_headers: false)) do |e|
        key, data = process_line(e, options)
        memo[key] = [] unless memo.key?(key)
        memo[key].concat(data)
      end
      memo
    end

    # Processes a line from source file. It is processed in
    # 2 formats. First mode is column_based.
    # It means getting all specific columns.
    # These are specified either by index or name. Multiple
    # values are provided by several rows for the same user
    #
    # Second mode is row based which means there are no headers
    # and number of columns can be variable. Each row specifies multiple
    # values for one user. It is implied that the file provides values
    # for just one label
    #
    # @param options [Hash]
    # @return
    def self.process_line(line, options = {})
      index = options[:user_column] || 0
      login = line[index]

      results = options[:labels].mapcat do |label|
        column = label[:column] || Range.new(1, -1)
        values = column.is_a?(Range) ? line.slice(column) : [line[column]]
        [create_filter(label, values.compact)]
      end
      [login, results]
    end

    def self.create_filter(label, values)
      {
        :label => label[:label],
        :values => values,
        :over => label[:over],
        :to => label[:to]
      }
    end

    # Processes values in a map reduce way so the result is as readable as possible and
    # poses minimal impact on the API
    #
    # @param options [Hash]
    # @return [Array]
    def self.reduce_results(data)
      data.map { |k, v| { login: k, filters: UserFilterBuilder.collect_labels(v) } }
    end

    # Groups the values by particular label. And passes each group to deduplication
    # @param options [Hash]
    # @return
    def self.collect_labels(data)
      data.group_by { |x| [x[:label], x[:over], x[:to]] }.map { |l, v| { label: l[0], over: l[1], to: l[2], values: UserFilterBuilder.collect_values(v) } }
    end

    # Collects specific values and deduplicates if necessary
    def self.collect_values(data)
      data.mapcat do |e|
        e[:values]
      end.uniq
    end

    def self.create_cache(data, key)
      data.reduce({}) do |a, e|
        a[e.send(key)] = e
        a
      end
    end

    def self.verify_existing_users(filters, options = {})
      project = options[:project]

      users_must_exist = options[:users_must_exist] == false ? false : true
      users_cache = options[:users_cache] || create_cache(project.users, :login)

      if users_must_exist
        list = users_cache.values
        missing_users = filters.map { |x| x[:login] }.reject { |u| project.member?(u, list) }
        fail "#{missing_users.count} users are not part of the project and variable cannot be resolved since :users_must_exist is set to true (#{missing_users.join(', ')})" unless missing_users.empty?
      end
    end

    def self.resolve_user_filter(user = [], project = [])
      user ||= []
      project ||= []
      to_create = user - project
      to_delete = project - user
      { :create => to_create, :delete => to_delete }
    end

    # Gets user defined filters and values from project regardless if they
    # come from Mandatory Filters or Variable filters and tries to
    # resolve what needs to be removed an what needs to be updated
    def self.resolve_user_filters(user_filters, vals)
      project_vals_lookup = vals.group_by(&:related_uri)
      user_vals_lookup = user_filters.group_by(&:related_uri)

      a = vals.map { |x| [x.related_uri, x] }
      b = user_filters.map { |x| [x.related_uri, x] }

      users_to_try = a.map(&:first).concat(b.map(&:first)).uniq
      results = users_to_try.map do |user|
        resolve_user_filter(user_vals_lookup[user], project_vals_lookup[user])
      end

      to_create = results.map { |x| x[:create] }.flatten.group_by(&:related_uri)
      to_delete = results.map { |x| x[:delete] }.flatten.group_by(&:related_uri)
      [to_create, to_delete]
    end

    private

    # Reads values from File/Array. Abstracts away the fact if it is column based,
    # row based or in file or provided inline as an array
    # @param file [String | Array] File or array of values to be parsed for filters
    # @param options [Hash] Filter definitions
    # @return [Array<Hash>]
    def self.get_values(file, options)
      file.is_a?(Array) ? read_array(file, options) : read_file(file, options)
    end

    # Reads array of values which are expected to be in a line wise manner
    # [
    #   ['john.doe@example.com', 'Engineering', 'Marketing']
    # ]
    # @param data [Array<Array>]
    def self.read_array(data, options = {})
      memo = {}
      data.each do |e|
        key, data = process_line(e, options)
        memo[key] = [] unless memo.key?(key)
        memo[key].concat(data)
      end
      memo
    end
  end
end
