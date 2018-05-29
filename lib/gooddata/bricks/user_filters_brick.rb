require_relative 'brick'

module GoodData::Bricks
  class UserFiltersBrick < GoodData::Bricks::Brick
    def version
      "0.0.1"
    end

    def call(params)
      GoodData::LCM2.perform('user_filters', params)
    end
  end
end
