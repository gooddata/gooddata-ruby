# encoding: utf-8

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'

require 'multi_json'

module GoodData
  class Dashboard
    class Tab
      attr_reader :dashboard
      attr_reader :json

      # Initializes new instance of Dashboard::Tab
      # @params json Raw json to create dashboard from
      # @params dashboard Dashboard this tab belongs to
      def initialize(json, dashboard)
        @json = json
        @dashboard = dashboard
      end

    end
  end
end
