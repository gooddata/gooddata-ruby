# encoding: UTF-8

# Local requires
require 'gooddata/models/models'

require_relative 'project_helper'

module DateTimeHelper
  TIMESTAMP ||= Time.new.strftime('%Y%m%d%H%M%S') + ".#{rand(1e6)}"
end