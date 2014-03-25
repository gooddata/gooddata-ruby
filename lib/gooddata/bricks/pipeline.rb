# encoding: UTF-8

require_relative 'base_downloader'
require_relative 'utils'

require_relative 'middleware/middleware'

module GoodData::Bricks
  class Pipeline
    def self.prepare(pipeline)
      pipeline.reverse.reduce(nil) do |memo, app|
        if memo.nil?
          app.respond_to?(:new) ? (app.new) : app
        else
          app.respond_to?(:new) ? (app.new(:app => memo)) : (app.app = memo; app)
        end
      end
    end
  end
end
