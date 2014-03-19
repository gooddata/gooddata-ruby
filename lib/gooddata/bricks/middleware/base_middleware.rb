module GoodData::Bricks

  class Middleware
    attr_accessor :app

    include GoodData::Bricks::Utils

    def initialize(options={})
      @app = options[:app]
    end

  end
end