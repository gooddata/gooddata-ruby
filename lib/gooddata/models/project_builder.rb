# encoding: UTF-8

require_relative 'dashboard_builder'
require_relative 'schema_builder'

module GoodData
  module Model
    class ProjectBuilder
      # attr_reader :title, :datasets, :reports, :metrics, :uploads, :users, :assert_report, :date_dimensions
      attr_accessor :data

      class << self
        def create_from_data(blueprint)
          ProjectBuilder.new(blueprint)
        end

        def create(title, _options = {}, &block)
          pb = ProjectBuilder.new(title: title)
          block.call(pb)
          pb
        end
      end

      def initialize(data = {})
        @data = data.to_hash.deep_dup
        @data[:datasets] = [] unless @data[:datasets]
        @data[:reports] = [] unless @data[:reports]
        @data[:assert_tests] = [] unless @data[:assert_tests]
        @data[:metrics] = [] unless @data[:metrics]
        @data[:uploads] = [] unless @data[:uploads]
        @data[:users] = [] unless @data[:users]
        @data[:dashboards] = [] unless @data[:dashboards]
        @data[:date_dimensions] = [] unless @data[:date_dimensions]
        @data[:title] = @data[:title]
      end

      def add_date_dimension(name, options = {})
        dimension = {
          urn: options[:urn],
          name: name,
          title: options[:title]
        }

        @data[:date_dimensions] << dimension
      end

      def add_dataset(name, &block)
        builder = GoodData::Model::SchemaBuilder.new(name)
        block.call(builder)
        if @data[:datasets].any? { |item| item[:name] == name }
          ds = @data[:datasets].find { |item| item[:name] == name }
          index = @data[:datasets].index(ds)
          stuff = GoodData::Model.merge_dataset_columns(ds, builder.to_hash)
          @data[:datasets].delete_at(index)
          @data[:datasets].insert(index, stuff)
        else
          @data[:datasets] << builder.to_hash
        end
      end

      def delete_dataset(a_dataset)
        index = datasets.index(find_dataset(a_dataset))
        datasets.delete_at(index)
        self
      end

      def add_report(title, options = {})
        @data[:reports] << { :title => title }.merge(options)
      end

      def add_metric(title, options = {})
        @data[:metrics] << { :title => title }.merge(options)
      end

      def add_dashboard(title, &block)
        db = DashboardBuilder.new(title)
        block.call(db)
        @data[:dashboards] << db.to_hash
      end

      def change_dataset(title, &block)
        b = SchemaBuilder.create_from_data(find_dataset(title))
        result = block.call(b)
        delete_dataset(title)
        datasets << result.to_hash
        self
      end

      def load_metrics(file)
        new_metrics = MultiJson.load(open(file).read, :symbolize_keys => true)
        @data[:metrics] += new_metrics
      end

      def load_datasets(file)
        new_metrics = MultiJson.load(open(file).read, :symbolize_keys => true)
        @data[:datasets] += new_metrics
      end

      def assert_report(report, result)
        @data[:assert_tests] << { :report => report, :result => result }
      end

      def upload(data, options = {})
        mode = options[:mode] || 'FULL'
        dataset = options[:dataset]
        @data[:uploads] << {
          :source => data,
          :mode => mode,
          :dataset => dataset
        }
      end

      def add_users(users)
        @data[:users] << users
      end

      def to_json(options = {})
        eliminate_empty = options[:eliminate_empty] || false

        if eliminate_empty
          JSON.pretty_generate(to_hash.reject { |_k, v| v.is_a?(Enumerable) && v.empty? })
        else
          JSON.pretty_generate(to_hash)
        end
      end

      def to_blueprint
        GoodData::Model::ProjectBlueprint.new(to_hash)
      end

      def to_hash
        @data
      end

      def datasets
        @data[:datasets]
      end

      def find_dataset(name)
        if name.is_a?(String)
          datasets.find { |d| d[:name] == name }
        elsif name.is_a?(Hash) && name.key?(:name)
          datasets.find { |d| d[:name] == name[:name] }
        end
      end
    end
  end
end
