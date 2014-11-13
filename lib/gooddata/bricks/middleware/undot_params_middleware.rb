# encoding: UTF-8

require_relative 'base_middleware'

module GoodData
  module Bricks
    # Converts params from double underscore notation to nested hash under 'config'
    # Parameters starting GDC_ are considered system params and aren't converted.
    #
    # This is useful because the executor platform can currently
    # do just key-value parameters. Also it makes it easier for
    # a user, as there aren't as much curly braces.
    #
    #
    # ### Examples
    # If you pass params in form:
    # {"my__namespace__param": "value"}
    #
    # you'll get:
    # {"my": {"namespace": {"param": value}}}
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
