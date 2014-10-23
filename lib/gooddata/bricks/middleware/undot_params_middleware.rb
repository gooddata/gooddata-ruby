require_relative 'base_middleware'

module GoodData
  module Bricks
    class UndotParamsMiddleware < Bricks::Middleware
      def call(params)
        params = params.to_hash
        unless params['config']
          # split the params to those starting with GDC and those that don't, put other params under config
          gdc_params, other_params = params.partition { |k, _| k =~ /GDC_.*/ }.map { |h| Hash[h] }
          params = gdc_params.merge('config' => other_params.undot)
        end
        @app.call(params)
      end
    end
  end
end
