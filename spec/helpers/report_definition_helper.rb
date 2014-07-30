# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'report_helper'

module ReportDefinitionHelper
  class << self
    def default_definition
      ReportHelper.default_report.definition
    end
  end
end
