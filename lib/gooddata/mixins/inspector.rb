# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# See https://gist.github.com/ubermajestix/3644301

module GoodData
  module Mixin
    # When an RSpec test like this fails,
    #
    #   @my_array.should == [@some_model, @some_model2]
    #
    # RSpec will call inspect on each of the objects to "help" you figure out
    # what went wrong. Well, inspect will usually dump a TON OF SHIT and make trying
    # to figure out why `@my_array` is not made up of `@some_model` and `@some_model2`.
    #
    # This little module and technique helps get around that. It will redefine `inspect`
    # if you include it in your model object.
    #
    # You can define a whitelist of methods that inspect will dump.
    # It will always provide `object_id` at a minimum.
    #
    # To use it, drop it in spec/support/inspector.rb and class_eval the models to
    # override `inspect`.
    module Inspector
      def inspect
        string = "#<#{self.class.name}:#{object_id} "
        fields = self.class.inspector_fields.map { |field| "#{field}: #{send(field)}" }
        string << fields.join(', ') << '>'
      end

      def self.inspected
        @inspected ||= []
      end

      def self.included(source)
        # $stdout.puts "Overriding inspect on #{source}"
        inspected << source
        source.class_eval do
          def self.inspector(*fields)
            @inspector_fields = *fields
          end

          def self.inspector_fields
            @inspector_fields ||= []
          end
        end
      end
    end
  end
end
