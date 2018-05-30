require 'hashdiff'

module Support
  class ComparisonHelper
    class << self
      def compare_dashboards(expected, actual)
        sanitized_expected = sanitize_dashboard_for_comparison(expected)
        sanitized_actual = sanitize_dashboard_for_comparison(actual)
        HashDiff.diff(sanitized_expected, sanitized_actual)
      end

      def compare_processes(expected, actual)
        sanitized_expected = sanitize_process_for_comparison(expected)
        sanitized_actual = sanitize_process_for_comparison(actual)
        HashDiff.diff(sanitized_expected, sanitized_actual)
      end

      def compare_schedules(expected, actual)
        sanitized_expected = sanitize_schedule_for_comparison(expected)
        sanitized_actual = sanitize_schedule_for_comparison(actual)
        HashDiff.diff(sanitized_expected, sanitized_actual)
      end

      def compare_reports(expected, actual)
        sanitized_expected = sanitize_report_for_comparison(expected)
        sanitized_actual = sanitize_report_for_comparison(actual)
        HashDiff.diff(sanitized_expected, sanitized_actual)
      end

      def compare_ldm(blueprint, project_id, rest_client)
        uri = "/gdc/projects/#{project_id}/model/diff?includeGrain=true&includeCA=true"
        result = rest_client.post(uri, blueprint.to_wire)
        polling_link = result['asyncTask']['link']['poll']
        response = rest_client.poll_on_code(polling_link)
        response['projectModelDiff']
      end

      private

      def sanitize_dashboard_for_comparison(dashboard)
        dashboard_dup = dashboard.dup

        dashboard_dup.data['meta'].delete('uri')
        dashboard_dup.data['meta'].delete('created')
        dashboard_dup.data['meta'].delete('updated')
        dashboard_dup.data['meta'].delete('locked')
        dashboard_dup.data['meta'].delete('author')
        dashboard_dup.data['meta'].delete('contributor')
        tabs = dashboard_dup.data['content']['tabs']
        tabs.each { |t| t.delete('identifier') }
        items = dashboard_dup.tabs.flat_map(&:items)
        items.each { |item| item.data.delete('obj') }
        dashboard_dup.data
      end

      def sanitize_report_for_comparison(report)
        data_dup = report.data.dup
        data_dup['content'].delete('definitions')
        data_dup['meta'].delete('created')
        data_dup['meta'].delete('uri')
        data_dup['meta'].delete('updated')
        data_dup['meta'].delete('locked')
        data_dup['meta'].delete('author')
        data_dup['meta'].delete('contributor')
        data_dup
      end

      def sanitize_schedule_for_comparison(schedule)
        data_dup = schedule.data.dup
        data_dup.delete('links')
        data_dup.delete('lastExecution')
        data_dup.delete('lastSuccessful')
        data_dup.delete('triggerScheduleId')
        data_dup.delete('consecutiveFailedExecutionCount')
        data_dup.delete('nextExecutionTime')
        data_dup['params'].delete('PROCESS_ID')
        data_dup['params'].delete('CLIENT_ID')
        data_dup['params'].delete('PROJECT_ID')
        data_dup['params'].delete('print_reverted')
        data_dup['params'].delete('GOODOT_CUSTOM_PROJECT_ID') # TMA-210
        data_dup['hiddenParams'].delete('SECURE_PARAM_2')

        # hidden parameters that are not also in additional_hidden_params
        # do not get transferred
        data_dup['hiddenParams'].delete('secure_param_1')
        data_dup['hiddenParams'].delete('secure_param_2')

        data_dup.delete('state')
        data_dup
      end

      def sanitize_process_for_comparison(process)
        data_dup = process.data.dup
        data_dup['process'].delete('links')
        data_dup['process'].delete('lastDeployed')
        data_dup
      end
    end
  end
end
