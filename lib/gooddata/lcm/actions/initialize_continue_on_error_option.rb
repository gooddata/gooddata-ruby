# frozen_string_literal: true
# (C) 2019-2022 GoodData Corporation
require_relative 'base_action'

module GoodData
  module LCM2
    class InitializeContinueOnErrorOption < BaseAction
      DESCRIPTION = 'Initialize continue on error option'

      PARAMS = define_params(self) do
        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'DataProduct'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Restricts synchronization to specified segments'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          project_mappings = ThreadSafe::Hash.new
          client_mappings = ThreadSafe::Hash.new
          continue_on_error = continue_on_error(params)

          if continue_on_error
            client = params.gdc_gd_client
            domain_name = params.organization || params.domain
            domain = client.domain(domain_name)
            data_product = params.data_product
            data_product_segments = domain.segments(:all, data_product)

            if params.segments_filter
              data_product_segments.select! do |segment|
                params.segments_filter.include?(segment.segment_id)
              end
            end

            data_product_segments.pmap do |segment|
              segment.clients.map do |segment_client|
                project = segment_client.project
                next unless project

                project_mappings[project.pid.to_sym] = {
                  client_id: segment_client.client_id,
                  segment_id: segment.segment_id
                }
                client_mappings[segment_client.client_id.to_sym] = {
                  project_id: project.pid,
                  segment_id: segment.segment_id
                }
              end
            end
          end

          {
            params: {
              collect_synced_status: continue_on_error,
              sync_failed_list: {
                project_client_mappings: project_mappings,
                client_project_mappings: client_mappings,
                failed_detailed_projects: [],
                failed_projects: [],
                failed_clients: [],
                failed_segments: []
              }
            }
          }
        end

        def print_result(_params)
          false
        end
      end
    end
  end
end
