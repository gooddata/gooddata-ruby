# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../project_log_formatter'

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

    def self.get_missing_users(filters, options = {})
      users_cache = options[:users_cache]
      filters.reject { |u| users_cache.key?(u[:login]) }
    end

    def self.verify_existing_users(filters, options = {})
      users_must_exist = options[:users_must_exist] == false ? false : true
      users_cache = options[:users_cache]
      domain = options[:domain]

      if users_must_exist
        missing_users = filters.reject do |u|
          next true if users_cache.key?(u[:login])
          domain_user = (domain && domain.find_user_by_login(u[:login]))
          users_cache[domain_user.login] = domain_user if domain_user
          next true if domain_user
          false
        end
        unless missing_users.empty?
          fail "#{missing_users.count} users are not part of the project and " \
               "variable cannot be resolved since :users_must_exist is set " \
               "to true (#{missing_users.join(', ')})"
        end
      end
    end

    def self.create_label_cache(result, options = {})
      project = options[:project]
      project_labels = project.labels

      result.reduce({}) do |a, e|
        e[:filters].map do |filter|
          a[filter[:label]] = project_labels.find { |l| (l.identifier == filter[:label]) || (l.uri == filter[:label]) } unless a.key?(filter[:label])
        end
        a
      end
    end

    def self.create_lookups_cache(small_labels)
      small_labels.reduce({}) do |a, e|
        lookup = e.values(:limit => 1_000_000).reduce({}) do |a1, e1|
          a1[e1[:value]] = e1[:uri]
          a1
        end
        a[e.uri] = lookup
        a
      end
    end

    def self.create_attrs_cache(filters, options = {})
      project = options[:project]

      labels = filters.flat_map do |f|
        f[:filters]
      end

      over_cache = labels.reduce({}) do |a, e|
        a[e[:over]] = e[:over]
        a
      end
      to_cache = labels.reduce({}) do |a, e|
        a[e[:to]] = e[:to]
        a
      end
      cache = over_cache.merge(to_cache)
      attr_cache = {}
      cache.each_pair do |k, v|
        begin
          attr_cache[k] = project.attributes(v)
        rescue
          nil
        end
      end
      attr_cache
    end

    # Walks over provided labels and picks those that have fewer than certain amount of values
    # This tries to balance for speed when working with small datasets (like users)
    # so it precaches the values and still be able to function for larger ones even
    # though that would mean tons of requests
    def self.get_small_labels(labels_cache)
      labels_cache.values.select { |label| label && label.values_count && label.values_count < 100_000 }
    end

    # Creates a MAQL expression(s) based on the filter defintion.
    # Takes the filter definition looks up any necessary values and provides API executable MAQL
    def self.create_expression(filter, labels_cache, lookups_cache, attr_cache, options = {})
      errors = []
      values = filter[:values]
      label = labels_cache[filter[:label]]
      element_uris = values.map do |v|
        begin
          if lookups_cache.key?(label.uri)
            if lookups_cache[label.uri].key?(v)
              lookups_cache[label.uri][v]
            else
              fail
            end
          else
            label.find_value_uri(v)
          end
        rescue
          errors << {
            type: :error,
            label: label.title,
            value: v
          }
          nil
        end
      end
      expression = if element_uris.compact.empty? && options[:restrict_if_missing_all_values] && options[:type] == :muf
                     '1 <> 1'
                   elsif element_uris.compact.empty? && options[:restrict_if_missing_all_values] && options[:type] == :variable
                     nil
                   elsif element_uris.compact.empty?
                     'TRUE'
                   elsif filter[:over] && filter[:to]
                     over = attr_cache[filter[:over]]
                     to = attr_cache[filter[:to]]
                     "([#{label.attribute_uri}] IN (#{element_uris.compact.sort.map { |e| '[' + e + ']' }.join(', ')})) OVER [#{over && over.uri}] TO [#{to && to.uri}]"
                   else
                     "[#{label.attribute_uri}] IN (#{element_uris.compact.sort.map { |e| '[' + e + ']' }.join(', ')})"
                   end
      if options[:ignore_missing_values]
        [expression, []]
      else
        [expression, errors]
      end
    end

    # Encapuslates the creation of filter
    def self.create_user_filter(expression, related)
      {
        related: related,
        level: :user,
        expression: expression,
        type: :filter
      }
    end

    # Resolves and creates maql statements from filter definitions.
    # This method does not perform any modifications on API but
    # collects all the information that is needed to do so.
    # Method collects all info from the user and current state in project and compares.
    # Returns suggestion of what should be deleted and what should be created
    # If there is some discrepancies in the data (missing values, nonexistent users) it
    # finishes and collects all the errors at once
    #
    # @param filters [Array<Hash>] Filters definition
    # @return [Array] first is list of MAQL statements
    def self.maqlify_filters(filters, options = {})
      fail_early = options[:fail_early] == false ? false : true
      users_cache = options[:users_cache]
      labels_cache = create_label_cache(filters, options)
      small_labels = get_small_labels(labels_cache)
      lookups_cache = create_lookups_cache(small_labels)
      attrs_cache = create_attrs_cache(filters, options)
      users = Hash[
        options[:project].users.map do |user|
          [user.login, user.profile_url]
        end
      ]
      create_filter_proc = proc do |login, f|
        expression, errors = create_expression(f, labels_cache, lookups_cache, attrs_cache, options)
        profiles_uri = if options[:type] == :muf
                         uri = users[login]
                         uri.nil? ? ('/gdc/account/profile/' + login) : uri
                       elsif options[:type] == :variable
                         (users_cache[login] && users_cache[login].uri)
                       else
                         fail 'Unsuported type in maqlify_filters.'
                       end

        if profiles_uri && expression && expression != 'TRUE'
          [create_user_filter(expression, profiles_uri)] + errors
        else
          [] + errors
        end
      end

      # if fail early process until first error
      results = if fail_early
                  x = filters.inject([true, []]) do |(enough, a), e|
                    login = e[:login]
                    if enough
                      y = e[:filters].pmapcat { |f| create_filter_proc.call(login, f) }
                      [!y.any? { |r| r[:type] == :error }, a.concat(y)]
                    else
                      [false, a]
                    end
                  end
                  x.last
                else
                  filters.flat_map do |filter|
                    login = filter[:login]
                    filter[:filters].pmapcat { |f| create_filter_proc.call(login, f) }
                  end
                end
      results.group_by { |i| i[:type] }.values_at(:filter, :error).map { |i| i || [] }
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

      a = vals.map(&:related_uri)
      b = user_filters.map(&:related_uri)

      users_to_try = (a + b).uniq
      results = users_to_try.map do |user|
        resolve_user_filter(user_vals_lookup[user], project_vals_lookup[user])
      end

      to_create = results.map { |x| x[:create] }.flatten.group_by(&:related_uri)
      to_delete = results.map { |x| x[:delete] }.flatten.group_by(&:related_uri)
      [to_create, to_delete]
    end

    # Executes the update for variables. It resolves what is new and needed to update.
    # @param filters [Array<Hash>] Filter Definitions
    # @param filters [Variable] Variable instance to be updated
    # @param options [Hash]
    # @option options [Boolean] :dry_run If dry run is true. No changes to he proejct are made but list of changes is provided
    # @return [Array] list of filters that needs to be created and deleted
    def self.execute_variables(filters, var, options = {})
      client = options[:client]
      project = options[:project]
      dry_run = options[:dry_run]
      to_create, to_delete = execute(filters, var.user_values, VariableUserFilter, options.merge(type: :variable))
      return [to_create, to_delete] if dry_run

      # TODO: get values that are about to be deleted and created and update them.
      # This will make sure there is no downitme in filter existence
      unless options[:do_not_touch_filters_that_are_not_mentioned]
        to_delete.each { |_, group| group.each(&:delete) }
      end
      data = to_create.values.flatten.map(&:to_hash).map { |var_val| var_val.merge(prompt: var.uri) }
      data.each_slice(200) do |slice|
        client.post("/gdc/md/#{project.obj_id}/variables/user", :variables => slice)
      end
      [to_create, to_delete]
    end

    def self.execute_mufs(user_filters, options = {})
      client = options[:client]
      project = options[:project]
      ignore_missing_values = options[:ignore_missing_values]
      users_must_exist = options[:users_must_exist] == false ? false : true
      dry_run = options[:dry_run]
      project_log_formatter = GoodData::ProjectLogFormatter.new(project)

      filters = normalize_filters(user_filters)
      user_filters, errors = maqlify_filters(filters, options.merge(users_must_exist: users_must_exist, type: :muf))

      fail GoodData::FilterMaqlizationError, errors if !ignore_missing_values && !errors.empty?
      filters = user_filters.map { |data| client.create(MandatoryUserFilter, data, project: project) }
      to_create, to_delete = resolve_user_filters(filters, project.data_permissions)

      if options[:do_not_touch_filters_that_are_not_mentioned]
        GoodData.logger.warn("Data permissions computed: #{to_create.count} to create")
      else
        GoodData.logger.warn("Data permissions computed: #{to_create.count} to create and #{to_delete.count} to delete")
      end
      return { created: to_create, deleted: to_delete } if dry_run

      create_results = to_create.each_slice(100).flat_map do |batch|
        batch.pmapcat do |related_uri, group|
          group.each(&:save)
          res = client.get("/gdc/md/#{project.pid}/userfilters?users=#{related_uri}")
          items = res['userFilters']['items'].empty? ? [] : res['userFilters']['items'].first['userFilters']

          payload = {
            'userFilters' => {
              'items' => [{
                'user' => related_uri,
                'userFilters' => items.concat(group.map(&:uri))
              }]
            }
          }
          res = client.post("/gdc/md/#{project.pid}/userfilters", payload)

          # turn the errors from hashes into array of hashes
          update_result = res['userFiltersUpdateResult'].flat_map do |k, v|
            v.map { |r| { status: k.to_sym, user: r, type: :create } }
          end

          update_result.map do |result|
            result[:status] == :failed ? result.merge(GoodData::Helpers.symbolize_keys(result[:user])) : result
          end
        end
      end

      project_log_formatter.log_user_filter_results(create_results, to_create)

      delete_results = unless options[:do_not_touch_filters_that_are_not_mentioned]
                         to_delete.each_slice(100).flat_map do |batch|
                           batch.flat_map do |related_uri, group|
                             results = []
                             if related_uri
                               res = client.get("/gdc/md/#{project.pid}/userfilters?users=#{related_uri}")
                               items = res['userFilters']['items'].empty? ? [] : res['userFilters']['items'].first['userFilters']
                               payload = {
                                 'userFilters' => {
                                   'items' => [
                                     {
                                       'user' => related_uri,
                                       'userFilters' => items - group.map(&:uri)
                                     }
                                   ]
                                 }
                               }
                               res = client.post("/gdc/md/#{project.pid}/userfilters", payload)
                               results.concat(res['userFiltersUpdateResult']
                                 .flat_map { |k, v| v.map { |r| { status: k.to_sym, user: r, type: :delete } } }
                                 .map { |result| result[:status] == :failed ? result.merge(GoodData::Helpers.symbolize_keys(result[:user])) : result })
                             end
                             group.peach(&:delete)
                             results
                           end
                         end
                       end

      project_log_formatter.log_user_filter_results(delete_results, to_delete)

      { created: to_create, deleted: to_delete, results: create_results + (delete_results || []) }
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

    # Executes the procedure necessary for loading user filters. This method has what
    # is common for both implementations. Funcion
    #   * makes sure that filters are in normalized form.
    #   * verifies that users are in the project (and domain)
    #   * creates maql expressions of the filters provided
    #   * resolves the filters against current values in the project
    # @param user_filters [Array] Filters that user is trying to set up
    # @param project_filters [Array] List of filters currently in the project
    # @param klass [Class] Class can be aither UserFilter or VariableFilter
    # @param options [Hash] Filter definitions
    # @return [Array<Hash>]
    def self.execute(user_filters, project_filters, klass, options = {})
      client = options[:client]
      project = options[:project]

      ignore_missing_values = options[:ignore_missing_values]
      users_must_exist = options[:users_must_exist] == false ? false : true
      filters = normalize_filters(user_filters)
      # domain = options[:domain]
      # users = domain ? project.users : project.users
      users = project.users
      users_cache = create_cache(users, :login)
      missing_users = get_missing_users(filters, options.merge(users_cache: users_cache))
      user_filters, errors = if missing_users.empty?
                               verify_existing_users(filters, project: project, users_must_exist: users_must_exist, users_cache: users_cache)
                               maqlify_filters(filters, options.merge(users_cache: users_cache, users_must_exist: users_must_exist))
                             elsif missing_users.count < 100
                               verify_existing_users(filters, project: project, users_must_exist: users_must_exist, users_cache: users_cache)
                               maqlify_filters(filters, options.merge(users_cache: users_cache, users_must_exist: users_must_exist))
                             else
                               users_cache = create_cache(users, :login)
                               verify_existing_users(filters, project: project, users_must_exist: users_must_exist, users_cache: users_cache)
                               maqlify_filters(filters, options.merge(users_cache: users_cache, users_must_exist: users_must_exist))
                             end

      fail GoodData::FilterMaqlizationError, errors if !ignore_missing_values && !errors.empty?
      filters = user_filters.map { |data| client.create(klass, data, project: project) }
      resolve_user_filters(filters, project_filters)
    end

    # Gets definition of filters from user. They might either come in the full definition
    # as hash or a simplified version. The simplified version do not cover all the possible
    # features but it is much simpler to remember and suitable for quick hacking around
    # @param filters [Array<Array | Hash>]
    # @return [Array<Hash>]
    def self.normalize_filters(filters)
      filters.map do |filter|
        if filter.is_a?(Hash)
          filter
        else
          {
            :login => filter.first,
            :filters => [
              {
                :label => filter[1],
                :values => filter[2..-1]
              }
            ]
          }
        end
      end
    end
  end
end
