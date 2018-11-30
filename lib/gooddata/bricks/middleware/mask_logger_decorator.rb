# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Bricks
    # Logger decorator with ability to mask sensitive values
    class MaskLoggerDecorator
      # entry-point
      # @param [Logger] logger logger to decorated
      # @param [Array] values_to_mask sensitive values to be masked out from logs
      def initialize(logger, values_to_mask = [])
        @logger = logger
        @values_to_mask = values_to_mask
      end

      # log methods to be decorated
      %i[debug error fatal info unknown warn].each do |level|
        define_method level do |message|
          @logger.send(level, mask(message))
        end
      end

      private

      # Masks given message.
      # @param message  [String] message to mask
      # @return masked_message [String] masked message
      def mask(message)
        unless message.nil?
          @values_to_mask.reduce(message) do |masked_message, value_to_mask|
            masked_message.gsub(value_to_mask, "******")
          end
        end
      end
    end
  end
end
