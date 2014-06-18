# encoding: UTF-8

module GoodData
  module Model
    class TabBuilder
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
