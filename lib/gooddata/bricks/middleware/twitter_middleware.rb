# encoding: UTF-8

# require 'twitter'

require_relative 'base_middleware'

module GoodData
  module Bricks
    class TwitterMiddleware < Bricks::Middleware
      def call(params)
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
