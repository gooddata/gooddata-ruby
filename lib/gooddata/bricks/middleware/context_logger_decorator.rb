# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Logger decorator with ability to enrich the message with brick context
  module ContextLoggerDecorator
    attr_accessor :context_source

    # log methods to be decorated
    def add(severity, message = nil, progname = nil)
      super(severity, enrich(message, context_source.context), progname)
    end

    private

    # Enrich given message.
    # @param message [String] or [Hash] message to enrich
    # @param context [Hash] context by which the message should be enriched
    # @return masked_message [String] or [Hash] enriched message
    def enrich(message, context)
      if !message
        context
      elsif message.is_a?(Hash)
        context.merge(message)
      else
        context.merge(message: message)
      end
    end
  end
end
