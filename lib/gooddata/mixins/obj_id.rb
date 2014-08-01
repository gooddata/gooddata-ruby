# encoding: UTF-8

module GoodData
  module Mixin
    module ObjId
      def obj_id
        uri.split('/').last
      end
    end
  end
end
