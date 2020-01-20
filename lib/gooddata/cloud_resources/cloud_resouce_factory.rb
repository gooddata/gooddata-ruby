# encoding: UTF-8
#
# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'active_support/core_ext/string/inflections'
require_relative 'cloud_resource_client'

module GoodData
  module CloudResources
    class CloudResourceFactory
      class << self
        def create(type, data = {}, opts = {})
          clients = CloudResourceClient.descendants.select { |c| c.respond_to?("accept?") && c.send("accept?", type) }
          raise "DataSource does not support type \"#{type}\"" if clients.empty?

          res = clients[0].new(data)
          opts.each do |key, value|
            method = "#{key}="
            res.send(method, value) if res.respond_to?(method)
          end
          res
        end
      end
    end
  end
end
