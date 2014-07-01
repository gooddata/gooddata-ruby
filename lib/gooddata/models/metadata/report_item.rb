# encoding: UTF-8

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class ReportItem
    attr_reader :json

    # Initializes new ReportItem instance from wire json
    def initialize(json)
      @json = json
    end
  end
end
