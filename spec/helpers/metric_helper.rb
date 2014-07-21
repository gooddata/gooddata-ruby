# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module MetricHelper
  DEFAULT_METRIC_NAME ||= 'Lines changed [Sum]'
  DEFAULT_METRIC_IDENTIFIER ||= 'afvbct52bgd2'
  DEFAULT_METRIC_URI ||= '/gdc/md/ghbpozicaidf1b9s0ohsa6msu7792c1k/obj/252'

  class << self
    def create_default_metric
    end

    def default_metric
      ProjectHelper.default_project.metrics.first
    end
  end
end
