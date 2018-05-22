# Copyright (c) 2018, GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# encoding: UTF-8

module GoodData
  module Connectors
    module Metadata
      class MetadataContext
        attr_accessor :default_folder, :account_id, :token, :data_source, :entity, :customer, :integrator

        def initialize(default_folder, account_id, token, data_source = nil)
          self.default_folder = default_folder
          self.account_id = account_id
          self.token = token
          self.data_source = data_source
        end

        def construct_full_data_path(entity, path, time = Time.new.utc)
          construct_full_path(data_source, entity, path, time)
        end

        def construct_full_batch_path(batch_id, path, time = Time.new.utc)
          construct_full_path('batches', batch_id, path, time)
        end

        def construct_full_cache_path(path)
          File.join(
            default_folder,
            account_id,
            token,
            'cache',
            path
          )
        end

        def construct_full_metadata_path(entity, path, time = Time.new.utc)
          construct_full_path('metadata', entity, path, time)
        end

        def construct_full_path(type, object, path, time = Time.new.utc)
          File.join(
            default_folder,
            account_id,
            token,
            type,
            object,
            TimeHelper.year(time),
            TimeHelper.month(time),
            TimeHelper.day(time),
            path
          )
        end

        def construct_path(level, path)
          case level
            when 1
              File.join(default_folder, account_id, path)
            when 2
              File.join(default_folder, account_id, token, path)
            when 3
              File.join(default_folder, account_id, token, data_source, path)
          end
        end
      end
    end
  end
end
