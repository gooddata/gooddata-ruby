# encoding: UTF-8

module GoodData
  module Mixin
    module Inspector
      Thread.current[:inspected_objects] = {}

      def inspected_objects
        Thread.current[:inspected_objects]
      end

      def inspect_recursion_guard
        inspected_objects[object_id] = true
        begin
          yield
        ensure
          inspected_objects.delete object_id
        end
      end

      def inspect_recursion?
        inspected_objects[object_id]
      end

      def inspect
        prefix = "#<#{self.class}:0x#{__id__.to_s(16)}"

        # If it's already been inspected, return the ...
        return "#{prefix} ...>" if inspect_recursion?

        # Otherwise, gather the ivars and show them.
        parts = []

        inspect_recursion_guard do
          instance_variables.each do |var|
            parts << "#{var}=#{instance_variable_get(var).inspect}"
          end
        end

        if parts.empty?
          str = "#{prefix}>"
        else
          str = "#{prefix} #{parts.join(' ')}>"
        end

        str.taint if tainted?

        str
      end
    end
  end
end
