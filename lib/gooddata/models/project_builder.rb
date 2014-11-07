# encoding: UTF-8

require_relative 'dashboard_builder'
require_relative 'schema_builder'

module GoodData
  module Model
    class ProjectBuilder
      attr_reader :title, :datasets, :reports, :metrics, :uploads, :users, :assert_report, :date_dimensions

      class << self
        def create_from_data(blueprint, title = 'Title')
          pb = ProjectBuilder.new(title)
          pb.data = blueprint.to_hash
          pb
        end

        def create(title, _options = {}, &block)
          pb = ProjectBuilder.new(title)
          block.call(pb)
          pb
        end
      end

      def initialize(title)
        @title = title
        @datasets = []
        @reports = []
        @assert_tests = []
        @metrics = []
        @uploads = []
        @users = []
        @dashboards = []
        @date_dimensions = []
      end

      def add_date_dimension(name, options = {})
        dimension = {
          urn: options[:urn],
          name: name,
          title: options[:title]
        }

        @date_dimensions << dimension
      end

      def add_dataset(name, &block)
        builder = GoodData::Model::SchemaBuilder.new(name)
        block.call(builder)
        if @datasets.any? { |item| item[:name] == name }
          ds = @datasets.find { |item| item[:name] == name }
          index = @datasets.index(ds)
          stuff = GoodData::Model.merge_dataset_columns(ds, builder.to_hash)
          @datasets.delete_at(index)
          @datasets.insert(index, stuff)
        else
          @datasets << builder.to_hash
        end
      end

      def add_report(title, options = {})
        @reports << { :title => title }.merge(options)
      end

      def add_metric(title, options = {})
        @metrics << { :title => title }.merge(options)
      end

      def add_dashboard(title, &block)
        db = DashboardBuilder.new(title)
        block.call(db)
        @dashboards << db.to_hash
      end

      def load_metrics(file)
        new_metrics = MultiJson.load(open(file).read, :symbolize_keys => true)
        @metrics += new_metrics
      end

      def load_datasets(file)
        new_metrics = MultiJson.load(open(file).read, :symbolize_keys => true)
        @datasets += new_metrics
      end

      def assert_report(report, result)
        @assert_tests << { :report => report, :result => result }
      end

      def upload(data, options = {})
        mode = options[:mode] || 'FULL'
        dataset = options[:dataset]
        @uploads << {
          :source => data,
          :mode => mode,
          :dataset => dataset
        }
      end

      def add_users(users)
        @users << users
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
        {
          :title => @title,
          :datasets => @datasets,
          :uploads => @uploads,
          :dashboards => @dashboards,
          :metrics => @metrics,
          :reports => @reports,
          :users => @users,
          :assert_tests => @assert_tests,
          :date_dimensions => @date_dimensions
        }
      end

      def find_dataset(name)
        datasets.find { |d| d.name == name }
      end
    end
  end
end
