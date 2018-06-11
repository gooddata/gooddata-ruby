# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'users_brick'
require_relative 'user_filters_brick'
require_relative 'release_brick'
require_relative 'provisioning_brick'
require_relative 'rollout_brick'

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

      def self.users_brick_pipeline
        prepare([
          DecodeParamsMiddleware,
          LoggerMiddleware,
          BenchMiddleware,
          GoodDataMiddleware,
          AWSMiddleware,
          WarehouseMiddleware,
          FsProjectUploadMiddleware.new(:destination => :staging),
          UsersBrick])
      end

      def self.user_filters_brick_pipeline
        prepare([
          DecodeParamsMiddleware,
          LoggerMiddleware,
          BenchMiddleware,
          GoodDataMiddleware,
          AWSMiddleware,
          FsProjectDownloadMiddleware.new(:source => :staging),
          FsProjectUploadMiddleware.new(:destination => :staging),
          WarehouseMiddleware,
          UserFiltersBrick])
      end

      def self.release_brick_pipeline
        prepare([
        DecodeParamsMiddleware,
        LoggerMiddleware,
        BenchMiddleware,
        GoodDataMiddleware,
        AWSMiddleware,
        WarehouseMiddleware,
        ReleaseBrick
        ])
      end

      def self.provisioning_brick_pipeline
        prepare([
        DecodeParamsMiddleware,
        LoggerMiddleware,
        BenchMiddleware,
        GoodDataMiddleware,
        AWSMiddleware,
        WarehouseMiddleware,
        ProvisioningBrick
        ])
      end

      def self.rollout_brick_pipeline
        prepare([
        DecodeParamsMiddleware,
        LoggerMiddleware,
        BenchMiddleware,
        GoodDataMiddleware,
        AWSMiddleware,
        WarehouseMiddleware,
        RolloutBrick
        ])
      end
    end
  end
end
