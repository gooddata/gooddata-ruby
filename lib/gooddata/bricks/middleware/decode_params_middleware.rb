require_relative 'base_middleware'

module GoodData
  module Bricks
    # Converts params from encoded hash to decoded hash
    class DecodeParamsMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash

        @app.call(GoodData::Helpers.decode_params(params))
      end
    end
  end
end
