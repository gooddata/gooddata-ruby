# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'meta_getter'

module GoodData
  module Mixin
    module MetaPropertyWriter
      def metadata_property_writer(*props)
        props.each do |prop|
          define_method "#{prop}=", proc { |val| meta[prop.to_s] = val }
        end
      end
    end
  end
end
