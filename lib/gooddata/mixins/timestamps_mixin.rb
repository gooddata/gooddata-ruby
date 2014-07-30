# encoding: UTF-8

module GoodData
  module Mixin
    module TimestampsMixin
      def updated
        Time.parse(meta['updated'])
      end

      def created
        Time.parse(meta['created'])
      end
    end
  end
end
