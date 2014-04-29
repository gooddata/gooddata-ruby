# encoding: UTF-8

module GoodData
  module Model
    class TabBuilder
      def initialize(title)
        @title = title
        @stuff = []
      end

      def add_report(options = {})
        @stuff << { :type => :report }.merge(options)
      end

      def to_hash
        {
          :title => @title,
          :items => @stuff
        }
      end
    end
  end
end
