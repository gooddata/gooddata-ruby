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
      def initialize(logger, params = [])
        @logger = logger
        @values_to_mask = GoodData::Bricks::MaskLoggerDecorator.extract_values(params)
      end

      class << self
        # Extract values to mask from structured data
        # @param values [String] or [Hash] or [Array] structured data to be extracted
        # @return [[String]] array of all String in values
        def extract_values(values)
          if values.is_a?(String)
            [values]
          elsif values.is_a?(Hash) || values.is_a?(Array)
            (values.is_a?(Hash) ? values.values : values).reduce([]) do |strings, item|
              strings.concat extract_values(item)
              strings
            end
          else
            []
          end
        end
      end

      # log methods to be decorated
      %i[debug error fatal info unknown warn].each do |level|
        define_method level do |message|
          @logger.send(level, mask(message))
        end
      end

      def debug?
        true
      end

      %i[warn? error? fatal? info?].each do |level|
        alias_method level, :debug?
      end

      # Decorator pretends being inner logger itselfs.
      # @return inner logger class
      def class
        @logger.class
      end

      def add(severity, message = nil, progname = nil)
        mask message
        mask progname
        @logger.add(severity, message, progname)
      end

      # Masks given message
      # @param message [String] or [Hash] or [Array] message to mask
      # @return masked_message [String] or [Hash] or [Array] masked message
      def mask(message)
        unless message.nil?
          string = message.to_s

          @values_to_mask.reduce(string) do |masked_message, value_to_mask|
            masked_message.gsub(value_to_mask, "******")
          end
        end
      end
    end
  end
end
