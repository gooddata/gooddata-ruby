# encoding: utf-8

module GoodData
  module Rest
    # Bridge between Rest::Object and Rest::Connection
    #
    # MUST be Responsible for creating new Rest::Object instances using proper Rest::Connection
    # SHOULD be used for throttling, statistics, custom 'allocation strategies' ...
    class ObjectFactory
      def initialize
        super
      end
    end
  end
end