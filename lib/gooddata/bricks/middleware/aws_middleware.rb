# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'aws-sdk'
require_relative 'base_middleware'

module GoodData
  module Bricks
    class AWSMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        if params.key?('aws_client')
          puts 'Setting up AWS-S3 connection'
          fail "Unable to connect to AWS. Parameter \"aws_client\" seems to be empty" unless params['aws_client']
          fail "Unable to connect to AWS. Parameter \"access_key_id\" is missing" if params['aws_client']['access_key_id'].blank?
          fail "Unable to connect to AWS. Parameter \"secret_access_key\" is missing" if params['aws_client']['secret_access_key'].blank?
          s3 = AWS::S3.new(params['aws_client'])
          params['aws_client']['s3_client'] = s3
          @app.call(params)
        else
          @app.call(params)
        end
      end
    end
  end
end
