# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module ReportHelper
  class << self
    @@REPORTS = []

    def default_report
      ProjectHelper.get_default_project.reports.first
    end

    # TODO: This function is responsible for creating new report which will be used for tests
    def create_default_reports
    end

    def remove_default_reports
      until @@REPORTS.empty?
        report = @@REPORTS.shift
        report.delete
      end
    end

    def delete_all_reports(project = ProjectHelper.get_default_project)
      project.delete_reports
    end

    def reports
      @@REPORTS
    end
  end
end
