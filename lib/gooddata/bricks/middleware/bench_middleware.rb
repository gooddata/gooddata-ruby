# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'benchmark'
require_relative 'base_middleware'

module GoodData
  module Bricks
    class BenchMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        puts 'Starting timer'
        result = nil
        report = Benchmark.measure { result = @app.call(params) }
        puts 'Stopping timer'
        pp report
        result
      end
    end
  end
end
