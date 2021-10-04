# encoding: UTF-8
# frozen_string_literal: true
# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class UpdateMetricFormats < BaseAction
      DESCRIPTION = 'Localize Metric Formats'

      PARAMS = define_params(self) do
        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: true

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: false

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: false

        description 'Localization query'
        param :localization_query, instance_of(Type::StringType), required: false
      end

      RESULT_HEADER = %i[action ok_clients error_clients]

      class << self
        def load_metric_data(params)
          if params&.dig(:input_source, :metric_format) && params[:input_source][:metric_format].present?
            metric_input_source = validate_input_source(params[:input_source])
          else
            return nil
          end

          metric_data_source = GoodData::Helpers::DataSource.new(metric_input_source)
          begin
            temp_csv = without_check(PARAMS, params) do
              File.open(metric_data_source.realize(params), 'r:UTF-8')
            end
          rescue StandardError => e
            GoodData.logger.warn("Unable to get metric input source, skip updating metric formats. Error: #{e.message} - #{e}")
            return nil
          end

          metrics_hash = GoodData::Helpers::Csv.read_as_hash temp_csv
          return nil if metrics_hash.empty?

          expected_keys = %w[tag client_id format]
          unless expected_keys.map(&:to_sym).all? { |s| metrics_hash.first.key? s }
            GoodData.logger.warn("The input metric data is incorrect, expecting the following fields: #{expected_keys}")
            return nil
          end
          metrics_hash
        end

        def validate_input_source(input_source)
          type = input_source[:type] if input_source&.dig(:type)
          metric_format = input_source[:metric_format]
          raise "Incorrect configuration: 'type' of 'input_source' is required" if type.blank?

          modified_input_source = input_source
          case type
          when 'ads', 'redshift', 'snowflake', 'bigquery', 'postgresql', 'mssql'
            if metric_format[:query].blank?
              GoodData.logger.warn("The metric input_source '#{type}' is missing property 'query'")
              return nil
            end

            modified_input_source[:query] = metric_format[:query]
            return modified_input_source
          when 's3'
            if metric_format[:file].blank?
              GoodData.logger.warn("The metric input_source '#{type}' is missing property 'file'")
              return nil
            end

            if modified_input_source.key?(:key)
              modified_input_source[:key] = metric_format[:file]
            else
              modified_input_source[:file] = metric_format[:file]
            end
            return modified_input_source
          when 'blobStorage'
            if metric_format[:file].blank?
              GoodData.logger.warn("The metric input_source '#{type}' is missing property 'file'")
              return nil
            end

            modified_input_source[:file] = metric_format[:file]
            return modified_input_source
          when 'staging'
            if metric_format[:file].blank?
              GoodData.logger.warn("The metric input_source '#{type}' is missing property 'file'")
              return nil
            end

            modified_input_source[:path] = metric_format[:file]
            return modified_input_source
          when 'web'
            if metric_format[:url].blank?
              GoodData.logger.warn("The metric input_source '#{type}' is missing property 'url'")
              return nil
            end

            modified_input_source[:url] = metric_format[:url]
            return modified_input_source
          else
            return nil
          end
        end

        def get_clients_metrics(metric_data)
          return {} if metric_data.nil?

          metric_groups = {}
          clients = metric_data.map { |row| row[:client_id] }.uniq
          clients.each do |client|
            next if client.blank?

            formats = {}
            metric_data.select { |row| row[:client_id] == client && row[:tag].present? && row[:format].present? }.each { |row| formats[row[:tag]] = row[:format] }
            metric_groups[client.to_s] ||= formats
          end
          metric_groups
        end

        def call(params)
          data = load_metric_data(params)
          result = []
          return result if data.nil?

          metric_group = get_clients_metrics(data)
          return result if metric_group.empty?

          GoodData.logger.debug("Clients have metrics which will be modified: #{metric_group.keys}")
          updated_clients = params.synchronize.map { |segment| segment.to.map { |client| client[:client_id] } }.flatten.uniq
          GoodData.logger.debug("Updating clients: #{updated_clients}")
          data_product = params.data_product
          data_product_clients = data_product.clients
          number_client_ok = 0
          number_client_error = 0
          metric_group.each do |client_id, formats|
            next unless updated_clients.include?(client_id)

            client = data_product_clients.find { |c| c.id == client_id }
            begin
              GoodData.logger.info("Start updating metric format for client: '#{client_id}'")
              metrics = client.project.metrics.to_a
              formats.each do |tag, format|
                next if tag.blank? || format.blank?

                metrics_to_be_updated = metrics.select { |metric| metric.tags.include?(tag) }
                metrics_to_be_updated.each do |metric|
                  metric.format = format
                  metric.save
                end
              end
              number_client_ok += 1
              GoodData.logger.info("Finished updating metric format for client: '#{client_id}'")
            rescue StandardError => e
              number_client_error += 1
              GoodData.logger.warn("Failed to update metric format for client: '#{client_id}'. Error: #{e.message} - #{e}")
            end
          end
          [{ :action => 'Update metric format', :ok_clients => number_client_ok, :error_clients => number_client_error }]
        end
      end
    end
  end
end
