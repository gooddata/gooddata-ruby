# encoding: UTF-8

require 'erubis'
require 'multi_json'

module GoodData
  module Model
    class DashboardBuilder
      DEFAULT_OPTS = {}

      TEMPLATES_DIR = File.join(File.dirname(__FILE__), '..', '..', 'templates', 'dashboard')

      class << self
        def construct_path(rel_path)
          File.join(TEMPLATES_DIR, rel_path)
        end

        def create(title, opts = DEFAULT_OPTS)
          opts = DEFAULT_OPTS.merge(opts)

          args = {
            :title => title || opts[:title] || "Default Dashboard #{Time.new.strftime('%Y%m%d%H%M%S')}",
            :summary => opts[:summary] || ''
          }

          dashoboard_json = template_as_json('dashboard.json.erb', args)

          GoodData::Dashboard.new(dashoboard_json)
        end

        def template_as_json(path, data)
          raw_json = GoodData::Helpers::Erb.template(construct_path(path), data)
          MultiJson.load(raw_json)
        end
      end

      # Initialize new dashboard
      def initialize(title)
        @title = title
        @tabs = []
        @dirty = false
      end

      attr_reader :dirty

      # Add tab to dashboard
      def add_tab(tab, &block)
        tb = TabBuilder.new(tab)

        # Call block if given
        block.call(tb) if block_given?

        # Add to array of tabs and mark dirty
        @tabs << tb
        @dirty = true
        tb
      end

      # Converts dashboard to hash
      def to_hash
        {
          :name => @name,
          :tabs => @tabs.map { |tab| tab.to_hash }
        }
      end

      # Saves new dashboard
      def save!
        @dirty = false if @dirty
        self
      end
    end
  end
end
