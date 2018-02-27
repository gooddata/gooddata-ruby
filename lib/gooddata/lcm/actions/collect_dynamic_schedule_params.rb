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
      end

      class << self
        def call(params)
          return [] unless params.dynamic_params

          schedule_title_column = params.schedule_title_column || 'schedule_title'
          client_id_column = params.client_id_column || 'client_id'
          param_name_column = params.param_name_column || 'param_name'
          param_value_column = params.param_value_column || 'param_value'
          results = []

          input_source = params.dynamic_params.input_source
          data_source = GoodData::Helpers::DataSource.new(input_source)
          input_data = File.open(data_source.realize(params), 'r:UTF-8')
          GoodData.logger.debug("Input data: #{input_data.read}")

          schedule_params = {}

          CSV.foreach(input_data, :headers => true, :return_headers => false, encoding: 'utf-8') do |row|
            GoodData.logger.debug("Processing row: #{row}")
            results << row.to_hash

            client_id = row[client_id_column] ? row[client_id_column] : :all_clients
            schedule_name = row[schedule_title_column] ? row[schedule_title_column] : :all_schedules

            schedule_params[client_id] ||= {}
            schedule_params[client_id][schedule_name] ||= {}

            schedule_params[client_id][schedule_name].merge!(row[param_name_column] => row[param_value_column])
          end

          {
            results: results,
            params: {
              schedule_params: schedule_params
            }
          }
        end
      end
    end
  end
end
