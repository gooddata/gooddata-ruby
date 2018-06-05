require_relative 'brick'

module GoodData::Bricks
  class ReleaseBrick < GoodData::Bricks::Brick
    def version
      '0.0.1'
    end

    # Provisioning brick entry-point
    #
    # @param [Hash] params Parameters
    # @option [String] 'associate' ('true') Do association - true, false
    # @option [String] 'provision' ('true') Do provision - true, false
    def call(params)
      GoodData::LCM2.perform('release', params)
    end
  end
end
