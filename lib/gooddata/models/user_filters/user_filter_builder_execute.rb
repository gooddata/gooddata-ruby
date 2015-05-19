# encoding: UTF-8

module GoodData
  module UserFilterBuilder
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

    def self.execute_mufs(filters, options = {})
      client = options[:client]
      project = options[:project]

      dry_run = options[:dry_run]
      to_create, to_delete = execute(filters, project.data_permissions, MandatoryUserFilter, options.merge(type: :muf))
      return [to_create, to_delete] if dry_run

      to_create.peach do |related_uri, group|
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
        to_delete.peach do |related_uri, group|
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
      domain = options[:domain]
      users = domain ? project.users + domain.users : project.users
      users_cache = create_cache(users, :login)
      verify_existing_users(filters, options.merge(users_must_exist: users_must_exist, users_cache: users_cache))
      user_filters, errors = maqlify_filters(filters, options.merge(users_cache: users_cache, users_must_exist: users_must_exist))
      fail "Validation failed #{errors}" if !ignore_missing_values && !errors.empty?

      filters = user_filters.map { |data| client.create(klass, data, project: project) }
      resolve_user_filters(filters, project_filters)
    end

    private

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
