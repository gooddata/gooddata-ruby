# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectUsersBrickUsers < BaseAction
      DESCRIPTION = 'Enriches parameters with users from the Users Brick input.'

      PARAMS = define_params(self) do
        description 'Input source of the Users Brick. Needed to prevent ' \
                    'deletion of filters for a user that is to be removed.'
        param :users_brick_config, instance_of(Type::UsersBrickConfig), required: true

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: false
      end

      class << self
        def call(params)
          users_brick_users = []
          login_column = params.users_brick_config.login_column || 'login'
          users_brick_data_source = GoodData::Helpers::DataSource.new(params.users_brick_config.input_source)

          users_brick_data_source_file = without_check(PARAMS, params) do
            File.open(
              users_brick_data_source.realize(params),
              'r:UTF-8'
            )
          end
          CSV.foreach(users_brick_data_source_file,
                      headers: true,
                      return_headers: false,
                      encoding: 'utf-8') do |row|
            users_brick_users << { login: row[login_column] }
          end

          {
            results: users_brick_users,
            params: {
              users_brick_users: users_brick_users
            }
          }
        end
      end
    end
  end
end
