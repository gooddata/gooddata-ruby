# encoding: UTF-8

require_relative '../exceptions/exceptions'
require_relative '../rest/rest'

module GoodData
  # Base class for Ruby SDK CLI Apps
  class App
    def main
      fail GoodData::NotImplementedError 'Application must implement #main'
    end
  end
end
