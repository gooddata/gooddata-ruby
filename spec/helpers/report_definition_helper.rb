# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'report_helper'

module ReportDefinitionHelper
  def self.default_definition
    ReportHelper.default_report.definition
  end
end
