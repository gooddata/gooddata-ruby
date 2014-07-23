# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module MetricHelper
  DEFAULT_METRIC_NAME ||= 'Lines changed [Sum]'
  DEFAULT_METRIC_IDENTIFIER ||= 'buRRk4Y4by0w'
  DEFAULT_METRIC_OBJ_ID ||= 241
  DEFAULT_METRIC_URI ||= "/gdc/md/#{ProjectHelper::PROJECT_ID}/obj/#{DEFAULT_METRIC_OBJ_ID}"

  class << self
    # TODO: Implement
    def create_default_metric
    end

    def default_metric
      ProjectHelper.default_project.metrics.first
    end

    # TODO: Implement
    def remove_default_metric
    end

  end
end
