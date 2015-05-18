# encoding: UTF-8

module GoodData
  module UserFilterBuilder
    def self.create_label_cache(result, options = {})
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
          errors << [label.title, v]
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
    def self.maqlify_filters(filters, options = {})
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
  end
end
