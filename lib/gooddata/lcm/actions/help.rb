# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/pipeline'

require_relative 'base_action'

module GoodData
  module LCM2
    # Action responsible for printing bricks help
    class Help < BaseAction
      DESCRIPTION = 'Print Help Message'

      PARAMS = {}

      class << self
        BRICK_PIPELINE_SUFFIX = /_brick_pipeline$/

        def create_help
          GoodData::Bricks::Pipeline.methods
            .grep(BRICK_PIPELINE_SUFFIX)
            .map { |method| method.to_s.sub(BRICK_PIPELINE_SUFFIX, '') }
            .map { |available_brick| { available_brick: available_brick } }
        end

        def call(_params)
          { results: create_help }
        end
      end
    end
  end
end
