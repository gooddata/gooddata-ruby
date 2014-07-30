# encoding: UTF-8

module GoodData
  module Mixin
    module ObjIdMixin
      def obj_id
        uri.split('/').last
      end
    end
  end
end
