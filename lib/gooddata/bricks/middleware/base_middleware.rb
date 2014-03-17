module GoodData::Bricks

  class Middleware
    attr_accessor :app

    include GoodData::Bricks::Utils

    def initialize(app=nil)
      @app = app
    end

  end
end