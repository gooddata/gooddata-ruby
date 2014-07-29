# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'
require_relative 'date_time_helper'

module ReportHelper
  DEFAULT_REPORT_TITLE_PREFIX = "Report #{DateTimeHelper::TIMESTAMP}"
  DEFAULT_REPORT_TITLE = "#{DEFAULT_REPORT_TITLE_PREFIX} Lines changed [Sum] - table"

  class << self
    @@REPORTS = []

    def default_report
      ProjectHelper.default_project.reports.first
    end

    # TODO: This function is responsible for creating new report which will be used for tests
    def create_default_reports
      project = ProjectHelper.default_project
      metric = MetricHelper.default_metric

      GoodData::ReportDefinitionBuilder.chart_types.each do |chart_type|
        title = "#{DEFAULT_REPORT_TITLE_PREFIX} #{metric.title} - #{chart_type}"
        definition = GoodData::ReportDefinitionBuilder.create(metric, :title => title, :type => chart_type)
        definition.save(project)

        report = GoodData::ReportBuilder.create(definition)
        report.save(project)

        @@REPORTS << report
      end
    end

    def remove_default_reports
      until @@REPORTS.empty?
        report = @@REPORTS.shift
        begin
          report.delete
        rescue Exception => e
          puts e
        end
      end
    end

    def remove_reports(project = ProjectHelper.default_project)
      project.delete_reports
    end

    def reports
      @@REPORTS
    end
  end
end
