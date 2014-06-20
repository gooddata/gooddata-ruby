# encoding: UTF-8

module GoodData
  module Model
    class DashboardBuilder
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
