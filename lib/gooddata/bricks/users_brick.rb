require_relative 'brick'

module GoodData::Bricks
  class UsersBrick < GoodData::Bricks::Brick
    def version
      '0.0.1'
    end

    def call(params)
      GoodData::LCM2.perform('users', params)
    end
  end
end
