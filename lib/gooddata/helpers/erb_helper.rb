require 'erb'

module GoodData
  module Helpers
    module ErbHelper
      class << self
        def template_string(template, params = {})
          b = binding

          params.each do |k, v|
            b.local_variable_set(k, v)
          end

          ERB.new(template).result(b)
        end

        def template_file(path, params)
          template_string(File.read(path), params)
        end
      end
    end
  end
end
