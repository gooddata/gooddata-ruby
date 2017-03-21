# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_middleware'

module GoodData
  module Bricks
    # Converts params from encoded hash to decoded hash
    class DecodeParamsMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash

        # Decode and resolve reference parameters in gd_encoded_params
        @app.call(GoodData::Helpers.decode_params(params, resolve_reference_params: true, convert_pipe_delimited_params: true))
      end
    end
  end
end
