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
      end

      class << self
        def call(params)
          return [] unless params.dynamic_params

          schedule_title_column = params.schedule_title_column || 'schedule_title'
          client_id_column = params.client_id_column || 'client_id'
          results = []

          dynamic_params = params.dynamic_params
          input_source = dynamic_params.input_source
          mapping = Hash[*dynamic_params.mapping.map { |m| [m[:column_name], m[:name]] }.flatten]
          mapping_columns = (mapping.keys + [schedule_title_column, client_id_column]).uniq

          data_source = GoodData::Helpers::DataSource.new(input_source)
          input_data = File.open(data_source.realize(params), 'r:UTF-8')
          GoodData.logger.debug("Input data: #{input_data.read}")

          CSV.foreach(input_data, :headers => true, :return_headers => false, encoding: 'utf-8') do |row|
            GoodData.logger.debug("Processing row: #{row}")
            row_data = Hash[*mapping_columns.map { |col| [mapping[col] || col, row[col]] }.flatten]
            results << row_data
          end

          schedule_params = results.group_by { |h| h[client_id_column] }
          schedule_params.keys.each do |k|
            schedule_params[k] = schedule_params[k].group_by { |v| v[schedule_title_column] }
          end

          schedule_params.keys.each do |client_id|
            schedule_params[client_id].keys.each do |schedule_name|
              reduced_params = schedule_params[client_id][schedule_name].reduce({}) { |a, b| a.merge(b) }
              schedule_params[client_id][schedule_name] = reduced_params.delete_if { |k, _| [schedule_title_column, client_id_column].include?(k) }
            end
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
