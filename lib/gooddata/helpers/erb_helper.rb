# encoding: UTF-8

require 'erubis'

module GoodData
  module Helpers
    class Erb
      class << self
        def template(path, data)
          input = File.read(path)
          eruby = Erubis::Eruby.new(input)
          eruby.result(data)
        end
      end
    end
  end
end
