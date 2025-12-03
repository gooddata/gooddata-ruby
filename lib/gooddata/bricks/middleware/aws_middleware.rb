# encoding: UTF-8
#
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'aws-sdk-s3'
require_relative 'base_middleware'

module GoodData
  module Bricks
    class AWSMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        s3_config = get_s3_config(params)

        unless s3_config.empty?
          GoodData.logger.info('Setting up AWS-S3 connection')
          if params.key?('aws_client')
            params['s3_client'] = {}
          elsif params.key?('s3_client')
            params['input_source'] = {} unless params.key?('input_source')
            params['input_source']['bucket'] = params['s3_client']['bucket']
          end
          s3_config = rewrite_for_aws_sdk_v2(s3_config)
          symbolized_config = GoodData::Helpers.symbolize_keys(s3_config)
          params['s3_client']['client'] = Aws::S3::Resource.new(symbolized_config)
        end
        @app.call(params)
      end

      private

      def get_s3_config(params)
        s3_config = {}
        if params.key?('aws_client')
          GoodData.logger.warn('Found two configuration aws_client and s3_client for S3 input source, use aws_client configuration') if params.key?('s3_client')
          raise 'Unable to connect to AWS. Parameter "aws_client" seems to be empty' unless params['aws_client']
          raise 'Unable to connect to AWS. Parameter "access_key_id" is missing' if params['aws_client']['access_key_id'].blank?
          raise 'Unable to connect to AWS. Parameter "secret_access_key" is missing' if params['aws_client']['secret_access_key'].blank?

          s3_config = params['aws_client']
        elsif params.key?('s3_client')
          raise 'Unable to connect to AWS. Parameter "s3_client" seems to be empty' unless params['s3_client']
          raise 'Unable to connect to AWS. Parameter "accessKey" is missing' if params['s3_client']['accessKey'].blank?
          raise 'Unable to connect to AWS. Parameter "secretKey" is missing' if params['s3_client']['secretKey'].blank?
          raise 'Unable to connect to AWS. Parameter "bucket" is missing' if params['s3_client']['bucket'].blank?

          s3_config['access_key_id'] = params['s3_client']['accessKey']
          s3_config['secret_access_key'] = params['s3_client']['secretKey']
          s3_config['region'] = params['s3_client']['region']
        end
        s3_config
      end

      def rewrite_for_aws_sdk_v2(config)
        config['region'] = 'us-west-2' unless config['region']
        if config['use_ssl']
          fail 'Parameter use_ssl has been deprecated. Version 2 of the AWS ' \
            'SDK uses SSL everywhere. To disable SSL you must ' \
            'configure an endpoint that uses http://.'
        end
        config.delete('endpoint') if config['endpoint'].nil? || config['endpoint'].to_s.strip.empty?
        config
      end
    end
  end
end
