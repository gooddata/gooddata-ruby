module GoodData::SmallGoodZilla

  def self.get_ids(a_maql_string)
    a_maql_string.scan(/!\[([^\"]+)\]/).flatten
  end

  def self.get_facts(a_maql_string)
    a_maql_string.scan(/#\"([^\"]+)\"/).flatten
  end

  def self.get_attributes(a_maql_string)
    a_maql_string.scan(/@\"([^\"]+)\"/).flatten
  end

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

  def self.interpolate_ids(*ids)
    res = GoodData::MdObject.identifier_to_uri(*ids.flatten)
    fail "Not all of the identifiers were resolved" if (Array(res).size != ids.flatten.size)
    res
  end

  def self.interpolate_values(keys, values)
    x = values.values_at(*keys)
    keys.zip(x)
  end

  def self.interpolate_metric(metric, dictionary)
    interpolated = interpolate({
      :facts => GoodData::SmallGoodZilla.get_facts(metric),
      :attributes => GoodData::SmallGoodZilla.get_attributes(metric),
      :metrics => GoodData::SmallGoodZilla.get_metrics(metric)
    }, dictionary)

    ids = GoodData::SmallGoodZilla.get_ids(metric)
    interpolated_ids = ids.zip(Array(interpolate_ids(ids)))

    metric = interpolated[:facts].reduce(metric) {|memo, item| memo.sub("#\"#{item[0]}\"", "[#{item[1]}]")}
    metric = interpolated[:attributes].reduce(metric) {|memo, item| memo.sub("@\"#{item[0]}\"", "[#{item[1]}]")}
    metric = interpolated[:metrics].reduce(metric) {|memo, item| memo.sub("?\"#{item[0]}\"", "[#{item[1]}]")}
    metric = interpolated_ids.reduce(metric) {|memo, item| memo.sub("![#{item[0]}]", "[#{item[1]}]")}
    metric

  end

end