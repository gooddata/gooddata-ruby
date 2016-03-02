# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# require 'twitter'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class TwitterMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        client = Twitter::REST::Client.new do |config|
          config.consumer_key = params[:twitter_consumer_key]
          config.consumer_secret = params[:twitter_consumer_secret]
          config.access_token = params[:twitter_access_token]
          config.access_token_secret = params[:twitter_access_token_secret]
        end

        returning(@app.call(params)) do |result|
          client.update(result)
        end
      end
    end
  end
end
