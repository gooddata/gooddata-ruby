# encoding: UTF-8

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

    def self.verify_existing_users(filters, options = { project: GoodData.project, client: GoodData.connection })
      project = options[:project]

      users_must_exist = options[:users_must_exist] == false ? false : true
      users_cache = options[:users_cache] || create_cache(project.users, :login)

      if users_must_exist
        list = users_cache.values
        missing_users = filters.map { |x| x[:login] }.reject { |u| project.member?(u, list) }
        fail "#{missing_users.count} users are not part of the project and variable cannot be resolved since :users_must_exist is set to true (#{missing_users.join(', ')})" unless missing_users.empty?
      end
    end

    def self.create_label_cache(result, options = { project: GoodData.project, client: GoodData.connection })
      project = options[:project]

      result.reduce({}) do |a, e|
        e[:filters].map do |filter|
          a[filter[:label]] = project.labels(filter[:label]) unless a.key?(filter[:label])
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

    # Walks over provided labels and picks those that have fewer than certain amount of values
    # This tries to balance for speed when working with small datasets (like users)
    # so it precaches the values and still be able to function for larger ones even
    # though that would mean tons of requests
    def self.get_small_labels(labels_cache)
      labels_cache.values.select { |label| label.values_count < 100_000 }
    end

    # Creates a MAQL expression(s) based on the filter defintion.
    # Takes the filter definition looks up any necessary values and provides API executable MAQL
    def self.create_expression(filter, labels_cache, lookups_cache, options = {})
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
          errors << [label, v]
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
                     "([#{label.attribute_uri}] IN (#{ element_uris.compact.sort.map { |e| '[' + e + ']' }.join(', ') })) OVER [#{filter[:over]}] TO [#{filter[:to]}]"
                   else
                     "[#{label.attribute_uri}] IN (#{ element_uris.compact.sort.map { |e| '[' + e + ']' }.join(', ') })"
                   end
      [expression, errors]
    end

    # Encapuslates the creation of filter
    def self.create_user_filter(expression, related)
      {
        'related' => related,
        'level' => :user,
        'expression' => expression,
        'type' => :filter
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
    def self.maqlify_filters(filters, options = { project: GoodData.project, client: GoodData.connection })
      project = options[:project]
      users_cache = options[:users_cache] || create_cache(project.users, :login)
      labels_cache = create_label_cache(filters, options)
      small_labels = get_small_labels(labels_cache)
      lookups_cache = create_lookups_cache(small_labels)

      errors = []
      results = filters.mapcat do |filter|
        login = filter[:login]
        filter[:filters].mapcat do |f|
          expression, error = create_expression(f, labels_cache, lookups_cache, options)
          errors << error unless error.empty?
          profiles_uri = (users_cache[login] && users_cache[login].uri)
          if profiles_uri && expression
            [create_user_filter(expression, profiles_uri)]
          else
            []
          end
        end
      end
      [results, errors]
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

    # Executes the update for variables. It resolves what is new and needed to update.
    # @param filters [Array<Hash>] Filter Definitions
    # @param filters [Variable] Variable instance to be updated
    # @param options [Hash]
    # @option options [Boolean] :dry_run If dry run is true. No changes to he proejct are made but list of changes is provided
    # @return [Array] list of filters that needs to be created and deleted
    def self.execute_variables(filters, var, options = { client: GoodData.connection, project: GoodData.project })
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

    def self.execute_mufs(filters, options = { client: GoodData.connection, project: GoodData.project })
      client = options[:client]
      project = options[:project]

      dry_run = options[:dry_run]
      to_create, to_delete = execute(filters, project.data_permissions, MandatoryUserFilter, options.merge(type: :muf))
      return [to_create, to_delete] if dry_run

      to_create.each_pair do |related_uri, group|
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
        client.post("/gdc/md/#{project.pid}/userfilters", payload)
      end
      unless options[:do_not_touch_filters_that_are_not_mentioned]
        to_delete.each do |related_uri, group|
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
            client.post("/gdc/md/#{project.pid}/userfilters", payload)
          end
          group.each(&:delete)
        end
      end
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
    def self.execute(user_filters, project_filters, klass, options = { client: GoodData.connection, project: GoodData.project })
      client = options[:client]
      project = options[:project]

      ignore_missing_values = options[:ignore_missing_values]
      users_must_exist = options[:users_must_exist] == false ? false : true
      filters = normalize_filters(user_filters)
      domain = options[:domain]
      users = domain ? project.users + domain.users : project.users
      users_cache = create_cache(users, :login)
      verify_existing_users(filters, options.merge(users_must_exist: users_must_exist, users_cache: users_cache))
      user_filters, errors = maqlify_filters(filters, options.merge(users_cache: users_cache, users_must_exist: users_must_exist))
      fail "Validation failed #{errors}" if !ignore_missing_values && !errors.empty?

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
