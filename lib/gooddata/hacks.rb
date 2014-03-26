# encoding: UTF-8

module GoodData
  module Hacks
    class << self
      def sleep_some_time(time)
        sleep(time)
      end
    end
  end
end
