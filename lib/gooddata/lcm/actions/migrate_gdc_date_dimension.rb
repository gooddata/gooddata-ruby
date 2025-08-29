# frozen_string_literal: true
# (C) 2019-2020 GoodData Corporation
require_relative 'base_action'

# Migrate date dimension urn:gooddata:date or urn:custom:date to urn:custom_v2:date
module GoodData
  module LCM2
    class MigrateGdcDateDimension < BaseAction
      DESCRIPTION = 'Migrate Gdc Date Dimension'
      DATE_DIMENSION_CUSTOM_V2 = 'urn:custom_v2:date'
      DATE_DIMENSION_OLD = %w[urn:gooddata:date urn:custom:date]

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Specifies how to synchronize LDM and resolve possible conflicts'
        param :synchronize_ldm, instance_of(Type::SynchronizeLDM), required: false, default: 'diff_against_master_with_fallback'

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Abort on error'
        param :abort_on_error, instance_of(Type::StringType), required: false

        description 'Logger'
        param :gdc_logger, instance_of(Type::GdLogger), required: false

        description 'Collect synced status'
        param :collect_synced_status, instance_of(Type::BooleanType), required: false

        description 'Sync failed list'
        param :sync_failed_list, instance_of(Type::HashType), required: false

        description 'Number Of Threads'
        param :number_of_threads_migrate_dates, instance_of(Type::StringType), required: false, default: '10'
      end

      RESULT_HEADER = %i[from to status]

      class << self
        def call(params)
          results = []
          params.synchronize.map do |segment_info|
            next if sync_failed_segment(segment_info[:segment_id], params)

            result = migrate_date_dimension(params, segment_info)
            results.concat(result)
          end

          {
            results: results
          }
        end

        def migrate_date_dimension(params, segment_info)
          results = []
          client = params.gdc_gd_client
          number_of_threads = Integer(params.number_of_threads_migrate_dates || '10')
          latest_blueprint = segment_info[:from_blueprint]
          # don't migrate when latest master doesn't contain custom v2 date.
          return results unless contain_v2?(latest_blueprint)

          previous_blueprint = segment_info[:previous_master]&.blueprint
          # check latest master and previous master
          master_upgrade_datasets = get_upgrade_dates(latest_blueprint, previous_blueprint) if params[:synchronize_ldm].downcase == 'diff_against_master' && previous_blueprint
          unless master_upgrade_datasets&.empty?
            collect_synced_status = collect_synced_status(params)
            failed_projects = ThreadSafe::Array.new

            segment_info[:to].pmap(number_of_threads) do |entry|
              pid = entry[:pid]
              next if sync_failed_project(pid, params)

              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")
              GoodData.logger.info "Migrating date dimension, project: '#{to_project.title}', PID: #{pid}"
              to_blueprint = to_project.blueprint
              upgrade_datasets = get_upgrade_dates(latest_blueprint, to_blueprint)
              next if upgrade_datasets.empty?

              message = get_upgrade_message(upgrade_datasets)
              failed_message = "Failed to migrate date dimension for project #{pid}"
              update_status = to_project.upgrade_custom_v2(message)
              process_failed_project(pid, failed_message, failed_projects, collect_synced_status) if collect_synced_status && update_status != 'OK'

              results << {
                from: segment_info[:from],
                to: pid,
                status: update_status
              }
            end

            process_failed_projects(failed_projects, short_name, params) if collect_synced_status
          end

          results
        end

        def get_upgrade_dates(src_blueprint, dest_blueprint)
          dest_dates = get_date_dimensions(dest_blueprint) if dest_blueprint
          src_dates = get_date_dimensions(src_blueprint) if src_blueprint

          upgrade_datasets = []
          return upgrade_datasets if dest_dates.empty? || src_dates.empty?

          dest_dates.each do |dest|
            src_dim = get_date_dimension(src_blueprint, dest[:id])
            next unless src_dim

            upgrade_datasets << src_dim[:identifier] if upgrade?(src_dim, dest) && src_dim[:identifier]
          end

          upgrade_datasets
        end

        def get_upgrade_message(upgrade_datasets)
          {
            upgrade: {
              dateDatasets: {
                upgrade: "exact",
                datasets: upgrade_datasets
              }
            }
          }
        end

        def upgrade?(src_dim, dest_dim)
          src_dim[:urn] == DATE_DIMENSION_CUSTOM_V2 && DATE_DIMENSION_OLD.any? { |e| dest_dim[:urn] == e }
        end

        def contain_v2?(blueprint)
          get_date_dimensions(blueprint).any? { |e| e[:urn] == DATE_DIMENSION_CUSTOM_V2 }
        end

        # Get date dimension from blue print. Return nil if date dimension not existing
        def get_date_dimension(blueprint, id)
          date_dimensions = get_date_dimensions(blueprint)
          date_dimensions.find { |d| d[:id] == id }
        end

        def get_date_dimensions(blueprint)
          GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)
        end
      end
    end
  end
end
