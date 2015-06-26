# encoding: UTF-8

module GoodData::Helpers
  module SpecHelper
    class << self
      def random_choice(possibilities, current_value)
        (possibilities - Array(current_value)).sample
      end
    end
  end
end
