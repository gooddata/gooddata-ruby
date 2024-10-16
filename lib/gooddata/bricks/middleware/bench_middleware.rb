# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'benchmark'
require_relative 'base_middleware'
require 'pp'

module GoodData
  module Bricks
    class BenchMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        GoodData.logger.info('Starting timer')
        result = nil
        report = Benchmark.measure { result = @app.call(params) }
        GoodData.logger.info('Stopping timer')
        GoodData.logger.info(report.pretty_inspect)
        result
      end
    end
  end
end
