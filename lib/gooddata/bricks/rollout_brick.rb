require_relative 'brick'

module GoodData::Bricks
  class RolloutBrick < GoodData::Bricks::Brick
    def version
      '0.0.1'
    end

    # Rollout brick entry-point
    def call(params)
      GoodData::LCM2.perform('rollout', params)
    end
  end
end
