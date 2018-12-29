# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Rest
    # class is responsible for storage and aggregation of REST calls information
    module Aggregator
      attr_reader :store

      def initialize_store
        @store = {}
      end

      def clear_store
        @store.clear
      end

      def update_store(domain, method, duration, endpoint)
        domain = domain.to_sym
        method = method.to_sym
        endpoint = endpoint.to_sym
        @store[domain] = {} unless @store.key?(domain)
        @store[domain][method] = {} unless @store[domain].key?(method)
        if @store[domain][method].key?(endpoint)
          record = @store[domain][method][endpoint]
          record[:min] = [duration, record[:min]].min
          record[:max] = [duration, record[:max]].max
          record[:avg] = (record[:avg] * record[:count] + duration).to_f / (record[:count] + 1)
          record[:count] += 1
          @store[domain][method][endpoint] = record
        else
          @store[domain][method][endpoint] = {
            :min => duration,
            :max => duration,
            :avg => duration,
            :count => 1,
            :method => method.to_s,
            :endpoint => endpoint.to_s,
            :domain => domain.to_s
          }
        end
      end
    end
  end
end
