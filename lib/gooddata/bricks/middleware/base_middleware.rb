# encoding: UTF-8

module GoodData::Bricks
  class Middleware
    include GoodData::Bricks::Utils

    def initialize(app)
      @app = app
    end
  end
end