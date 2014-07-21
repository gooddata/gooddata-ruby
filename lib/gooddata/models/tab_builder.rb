# encoding: UTF-8

module GoodData
  module Model
    class TabBuilder
      DEFAULT_OPTS = {
        :title => "Tab @ #{Time.new.strftime('%Y%m%d%H%M%S')}"
      }

      TEMPLATES_DIR = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'dashboard')

      class << self
        def construct_path(rel_path)
          File.join(TEMPLATES_DIR, rel_path)
        end

        def create(dashboard, opts = DEFAULT_OPTS, &block)
          opts = DEFAULT_OPTS.merge(opts)

          json = template_as_json('dashboard_tab.json.erb', opts)

          res = GoodData::Dashboard::Tab.new(dashboard, json)
          yield res if block_given?
          res
        end

        def template_as_json(path, data)
          raw_json = GoodData::Helpers::Erb.template(construct_path(path), data)
          MultiJson.load(raw_json)
        end
      end

      # Initialize new tab
      # @param [String] title Tab title
      def initialize(title)
        @title = title
        @stuff = []
      end

      # Adds report to tab
      def add_report(options = {})
        @stuff << { :type => :report }.merge(options)
      end

      # Converts tab to hash
      def to_hash
        {
          :title => @title,
          :items => @stuff
        }
      end
    end
  end
end
