# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require_relative 'purge_clients'

module GoodData
  module LCM2
    class ProvisionClients < BaseAction
      DESCRIPTION = 'Provisions LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GDDataProductType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: false

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false
      end

      RESULT_HEADER = [
        :id,
        :status,
        :project_uri,
        :error,
        :type
      ]

      class << self
        def call(params)
          synchronize_projects = []
          data_product = params.data_product
          client = params.gdc_gd_client
          collect_synced_status = collect_synced_status(params)
          continue_on_error = continue_on_error(params)
          domain_name = params.organization || params.domain
          fail "Either organisation or domain has to be specified in params" unless domain_name
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          error_message = nil
          invalid_client_ids = []
          begin
            results = params.segments.map do |segment|
              next if sync_failed_segment(segment.segment_id, params)

              segment_object = domain.segments(segment.segment_id, data_product)
              tmp = segment_object.provision_client_projects.map do |m|
                Hash[m.each_pair.to_a].merge(type: :provision_result)
              end

              unless tmp.empty?
                synchronize_project = {
                  segment_id: segment.segment_id,
                  from: segment.development_pid,
                  to: tmp.map do |entry|
                    unless entry[:project_uri]
                      error_message = "There was error during provisioning clients: #{entry[:error]}" unless error_message
                      invalid_client_ids << entry[:id]
                      if collect_synced_status
                        failed_message = "Failed to provision client #{entry[:id]} in segment #{segment.segment_id}. Error: #{entry[:error]}"
                        add_failed_client(entry[:id], failed_message, short_name, params)
                      end
                      next
                    end

                    project_id = entry[:project_uri].split('/').last
                    if collect_synced_status && entry[:status] == 'CREATED' && entry[:id]
                      # Update project client mappings when there are create new clients during provision clients of the segment
                      add_project_client_mapping(project_id, entry[:id], segment.segment_id, params)
                    end

                    {
                      pid: project_id,
                      client_id: entry[:id]
                    }
                  end.compact
                }

                synchronize_projects << synchronize_project unless synchronize_project[:to].empty?
              end

              if error_message
                params.gdc_logger.debug "#{error_message}. Purge all invalid clients now ..."
                deleted_client_ids = []

                segment_object.clients.map do |segment_client|
                  project = segment_client.project
                  if (project.nil? || project.deleted?)
                    client_id =  segment_client.client_id
                    if invalid_client_ids.include?(client_id)
                      segment_client.delete
                      deleted_client_ids << client_id
                    end
                  end
                end

                params.gdc_logger.debug "Deleted clients: #{deleted_client_ids.join(', ')}"
                unless error_message['TooManyProjectsCreatedException'] || error_message['Max number registered projects']
                  raise error_message unless continue_on_error

                  next
                end

                break tmp
              end

              tmp
            end
          rescue => e
            params.gdc_logger.error "Problem occurs when provisioning clients. Error: #{e}"
            raise e unless continue_on_error
          end

          results.flatten! if results

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_projects
            }
          }
        end
      end
    end
  end
end
