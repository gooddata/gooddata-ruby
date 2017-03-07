# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Bricks
    class Pipeline
      # Pipeline preparation code
      def self.prepare(pipeline)
        pipeline.reverse.reduce(nil) do |memo, app|
          if memo.nil?
            app.respond_to?(:new) ? app.new : app
          elsif app.respond_to?(:new)
            app.new(app: memo)
          else
            app.app = memo
            app
          end
        end
      end
    end
  end
end
