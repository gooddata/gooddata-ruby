# encoding: UTF-8

require_relative '../../core/core'
require_relative '../../mixins/root_key_mixin'
require_relative '../metadata'

require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class ReportItem
    class << self
      include GoodData::Mixin::RootKeyMixin
    end

    root_key :reportItem

    attr_reader :json

    # Initializes new ReportItem instance from wire json
    def initialize(json)
      @json = json
    end

    # Returns associated report
    # @return GoodData::Report
    def report
      url = uri
      return nil if url.nil?

      raw_json = GoodData.get url
      GoodData::Report.new(raw_json)
    end

    def uri
      return nil if json[root_key].nil?
      json[root_key]['obj']
    end
  end
end
