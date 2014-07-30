# encoding: UTF-8

module GoodData
  module Mixin
    module RootKeySetter
      def root_key(a_key)
        define_method :root_key, proc { a_key.to_s }
      end
    end
  end
end
