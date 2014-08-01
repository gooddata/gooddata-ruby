# encoding: UTF-8

module GoodData
  module Mixin
    module MdObjId
      def obj_id(uri)
        uri.split('/').last
      end
    end
  end
end
