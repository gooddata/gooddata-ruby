# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_downloader'
require_relative 'utils'

require_relative 'middleware/middleware'

module GoodData
  module Bricks
    # Brick base class
    class Brick
      def log(message)
        logger = @params[:gdc_logger]
        logger.info(message) unless logger.nil?
      end

      # Name of the brick
      def name
        self.class
      end

      # Version of brick, this should be implemented in subclasses
      def version
        fail NotImplementedError, 'Method version should be reimplemented'
      end

      # Bricks implementation which can be 'called'
      def call(params = {})
        @params = params
        ''
      end
    end
  end
end
