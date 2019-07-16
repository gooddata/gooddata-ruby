# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectDymanicScheduleParams < BaseAction
      DESCRIPTION = 'Collect Dynamic Schedule Params'

      PARAMS = define_params(self) do
        description 'Schedule Title Column'
        param :schedule_title_column, instance_of(Type::StringType), required: false

        description 'Dynamic Params'
        param :dynamic_params, instance_of(Type::HashType), required: false

        description 'Client Id Column'
        param :client_id_column, instance_of(Type::StringType), required: false

        description 'Name Column'
        param :param_name_column, instance_of(Type::StringType), required: false

        description 'Value Column'
        param :param_value_column, instance_of(Type::StringType), required: false

        description 'Should the param be hidden?'
        param :param_secure_column, instance_of(Type::StringType), required: false

        description 'Dynamic params encryption key'
        param :dynamic_params_encryption_key, instance_of(Type::StringType), required: false
      end

      class << self
        def call(params)
          return [] unless params.dynamic_params

          schedule_title_column = params.schedule_title_column || 'schedule_title'
          client_id_column = params.client_id_column || 'client_id'
          param_name_column = params.param_name_column || 'param_name'
          param_value_column = params.param_value_column || 'param_value'
          param_secure_column = params.param_secure_column || 'param_secure'

          encryption_key = params.dynamic_params_encryption_key || ''
          exist_encryption_key = encryption_key.blank? ? false : true

          results = []

          input_source = params.dynamic_params.input_source
          data_source = GoodData::Helpers::DataSource.new(input_source)
          input_data = without_check(PARAMS, params) do
            File.open(data_source.realize(params), 'r:UTF-8')
          end

          schedule_params = {}
          schedule_hidden_params = {}
          exist_param_secure = false

          CSV.foreach(input_data, :headers => true, :return_headers => false, encoding: 'utf-8') do |row|
            is_param_secure = row[param_secure_column] == 'true'
            is_decrypt_secure_value = is_param_secure && exist_encryption_key ? true : false
            exist_param_secure = true if is_param_secure

            safe_to_print_row = row.to_hash
            safe_to_print_row[param_value_column] = '******' if is_param_secure
            GoodData.logger.debug("Processing row: #{safe_to_print_row}")
            results << safe_to_print_row

            client_id_column_value = row[client_id_column]
            client_id = client_id_column_value.blank? ? :all_clients : client_id_column_value

            schedule_title_column_value = row[schedule_title_column]
            schedule_name = schedule_title_column_value.blank? ? :all_schedules : schedule_title_column_value

            param_name = row[param_name_column]
            param_value = row[param_value_column]
            param_value = GoodData::Helpers.simple_decrypt(param_value, encryption_key) if is_decrypt_secure_value

            add_dynamic_param(is_param_secure ? schedule_hidden_params : schedule_params, client_id, schedule_name, param_name, param_value)
          end

          GoodData.logger.warn("dynamic_params_encryption_key parameter doesn't exist") if exist_param_secure && !exist_encryption_key

          {
            results: results,
            params: {
              schedule_params: schedule_params,
              schedule_hidden_params: schedule_hidden_params
            }
          }
        end

        private

        def add_dynamic_param(params, client_id, schedule_name, param_name, param_value)
          params[client_id] ||= {}
          params[client_id][schedule_name] ||= {}
          params[client_id][schedule_name].merge!(param_name => param_value)
        end
      end
    end
  end
end
