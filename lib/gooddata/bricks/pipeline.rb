# encoding: UTF-8

require_relative 'base_downloader'
require_relative 'utils'

require_relative 'middleware/middleware'

module GoodData
  module Bricks
    class Pipeline
      # Pipeline preparation code
      def self.prepare(pipeline)
        pipeline.reverse.reduce(nil) do |memo, app|
          if memo.nil?
            app.respond_to?(:new) ? (app.new) : app
          else
            if app.respond_to?(:new)
              app.new(:app => memo)
            else
              app.app = memo
              app
            end
          end
        end
      end
    end
  end
end
