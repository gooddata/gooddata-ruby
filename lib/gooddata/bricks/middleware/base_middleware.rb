# encoding: UTF-8

# hash with deep merge to be used in merging defaults to runtime
class Hash
  def deep_merge(second)
    merger = proc { |key, v1, v2| v1.is_a?(Hash) && v2.is_a?(Hash) ? v1.merge(v2, &merger) : v2 }
    merge(second, &merger)
  end
end

module GoodData
  module Bricks
    class Middleware
      attr_accessor :app

      include Bricks::Utils

      def load_defaults(params)
        # if default params given, fill what's not given in runtime params
        if @config
          # load it from file and put it in the right namespace
          default_params = MultiJson.load(File.read(@config))
          if @config_namespace
            default_params = (['config'] + @config_namespace.split('__') + [default_params]).reverse.reduce { |a, e| { e => a } }
          end

          params = default_params.deep_merge(params)
        end
        params
      end

      def call(params)
        params = load_defaults(params)
        default_loaded_call(params)
      end

      def default_loaded_call(params)
        fail NotImplementedError, 'Needs to be implemented in a subclass'
      end

      def initialize(options = {})
        @app = options[:app]
      end
    end
  end
end
