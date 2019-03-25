# Copyright (c) 2010-2019 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Helpers
    module DataSourceHelper
      class << self
        def create_snowflake_data_source(rest_client)
          data_source_data = {
            dataSource: {
              name: 'Snowflake DS1',
              prefix: 'OUT_',
              connectionInfo: {
                snowflake: {
                  url: 'jdbc:snowflake://acme.snowflakecomputing.com',
                  userName: 'test',
                  password: 'test',
                  database: 'TEST',
                  schema: 'SCHEMA',
                  warehouse: 'DWH'
                }
              }
            }
          }
          data_source = rest_client.post('/gdc/dataload/dataSources', data_source_data)
          data_source['dataSource']['id']
        end

        def delete(id)
          # uncomment this after R181 code drop (May 4th)
          # @rest_client.delete("/gdc/dataload/dataSources/#{id}")
        end
      end
    end
  end
end
