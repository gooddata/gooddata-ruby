# encoding: UTF-8

module GoodData
  module Model
    class DashboardBuilder
      def initialize(title)
        @title = title
        @tabs = []
      end

      def add_tab(tab, &block)
        tb = TabBuilder.new(tab)
        block.call(tb)
        @tabs << tb
        tb
      end

      def to_hash
        {
          :name => @name,
          :tabs => @tabs.map(&:to_hash)
        }
      end
    end
  end
end
