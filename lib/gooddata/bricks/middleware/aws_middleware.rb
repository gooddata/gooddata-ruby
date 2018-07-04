# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'aws-sdk-s3'
require_relative 'base_middleware'

module GoodData
  module Bricks
    class AWSMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        if params.key?('aws_client')
          puts 'Setting up AWS-S3 connection'
          raise 'Unable to connect to AWS. Parameter "aws_client" seems to be empty' unless params['aws_client']
          raise 'Unable to connect to AWS. Parameter "access_key_id" is missing' if params['aws_client']['access_key_id'].blank?
          raise 'Unable to connect to AWS. Parameter "secret_access_key" is missing' if params['aws_client']['secret_access_key'].blank?
          params['aws_client'] = rewrite_for_aws_sdk_v2(params['aws_client'])
          symbolized_config = GoodData::Helpers.symbolize_keys(params['aws_client'])
          s3 = Aws::S3::Resource.new(symbolized_config)
          params['aws_client']['s3_client'] = s3
        end
        @app.call(params)
      end

      private

      def rewrite_for_aws_sdk_v2(config)
        config['region'] = 'us-west-2' unless config['region']
        if config['use_ssl']
          fail 'Parameter use_ssl has been deprecated. Version 2 of the AWS ' \
            'SDK uses SSL everywhere. To disable SSL you must ' \
            'configure an endpoint that uses http://.'
        end
        config
      end
    end
  end
end
