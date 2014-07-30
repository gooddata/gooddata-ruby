# encoding: UTF-8

module GoodData
  module Mixin
    module NotExportable
      def exportable?
        false
      end
    end
  end
end
