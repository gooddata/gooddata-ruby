# encoding: utf-8

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'

require 'multi_json'

module GoodData
  class Dashboard
    # Dashboard tab representation
    class Tab
      attr_reader :dashboard
      attr_reader :json

      # Gets identifier of the tab
      # @return [String] Dashboard tab identifier
      def identifier
        json['identifier']
      end

      # Initializes new instance of Dashboard::Tab
      # @params json Raw json to create dashboard from
      # @params dashboard Dashboard this tab belongs to
      def initialize(json, dashboard)
        @json = json
        @dashboard = dashboard
      end

      # Returns dashboard tab items
      def items
        json['items'].map do |item|
          GoodData::ReportItem.new(item)
        end
      end

      # Gets Dashboard tab title
      # @return [String] Dashboard tab title
      def title
        json['title']
      end
    end
  end
end
