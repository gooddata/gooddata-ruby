# encoding: UTF-8

module GoodData
  module SmallGoodZilla
    # Get IDs from MAQL string
    # @param a_maql_string Input MAQL string
    # @return [Array<String>] List of IDS
    def self.get_ids(a_maql_string)
      a_maql_string.scan(/!\[([^\"\]]+)\]/).flatten.uniq
    end

    # Get Facts from MAQL string
    # @param a_maql_string Input MAQL string
    # @return [Array<String>] List of Facts
    def self.get_facts(a_maql_string)
      a_maql_string.scan(/#\"([^\"]+)\"/).flatten
    end

    # Get Attributes from MAQL string
    # @param a_maql_string Input MAQL string
    # @return [Array<String>] List of Attributes
    def self.get_attributes(a_maql_string)
      a_maql_string.scan(/@\"([^\"]+)\"/).flatten
    end

    # Get Metrics from MAQL string
    # @param a_maql_string Input MAQL string
    # @return [Array<String>] List of Metrics
    def self.get_metrics(a_maql_string)
      a_maql_string.scan(/\?"([^\"]+)\"/).flatten
    end

    def self.interpolate(values, dictionaries)
      {
        :facts => interpolate_values(values[:facts], dictionaries[:facts]),
        :attributes => interpolate_values(values[:attributes], dictionaries[:attributes]),
        :metrics => interpolate_values(values[:metrics], dictionaries[:metrics])
      }
    end

    def self.interpolate_ids(options, *ids)
      ids = ids.flatten
      if ids.empty?
        []
      else
        res = GoodData::MdObject.identifier_to_uri(options, *ids)
        fail 'Not all of the identifiers were resolved' if Array(res).size != ids.size
        res
      end
    end

    def self.interpolate_values(keys, values)
      x = values.values_at(*keys)
      keys.zip(x)
    end

    def self.interpolate_metric(metric, dictionary, options = { :client => GoodData.connection, :project => GoodData.project })
      interpolated = interpolate({
                                   :facts => GoodData::SmallGoodZilla.get_facts(metric),
                                   :attributes => GoodData::SmallGoodZilla.get_attributes(metric),
                                   :metrics => GoodData::SmallGoodZilla.get_metrics(metric)
                                 }, dictionary)

      ids = GoodData::SmallGoodZilla.get_ids(metric)
      interpolated_ids = ids.zip(Array(interpolate_ids(options, ids)))

      metric = interpolated[:facts].each_with_object(metric) { |a, e| a.sub("#\"#{e[0]}\"", "[#{e[1]}]") }
      metric = interpolated[:attributes].each_with_object(metric) { |a, e| a.sub("@\"#{e[0]}\"", "[#{e[1]}]") }
      metric = interpolated[:metrics].each_with_object(metric) { |a, e| a.sub("?\"#{e[0]}\"", "[#{e[1]}]") }
      metric = interpolated_ids.each_with_object(metric) { |a, e| a.gsub("![#{e[0]}]", "[#{e[1]}]") }
      metric
    end
  end
end
