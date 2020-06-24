# frozen_string_literal: true
# (C) 2019-2020 GoodData Corporation
require_relative 'base_action'

#Migrate date dimension urn:gooddata:date or urn:custom:date to urn:custom_v2:date
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
      end

      RESULT_HEADER = %i[from to status]

      class << self
        def call(params)
          results = []
          params.synchronize.map do |segment_info|
            result = synchronize_date_dimension(params, segment_info)
            results.concat(result)
          end

          {
            results: results
          }
        end

        def synchronize_date_dimension(params, segment_info)
          results = []
          client = params.gdc_gd_client
          diff_against_master = %w[diff_against_master].include?(params[:synchronize_ldm].downcase)
          latest_blueprint = segment_info[:latest_master]&.blueprint(include_ca: true)
          previous_blueprint = segment_info[:previous_master]&.blueprint(include_ca: true)
          is_upgrade = true
          # check latest master and previous master
          is_upgrade = blueprint_upgrade(latest_blueprint, previous_blueprint) if diff_against_master
          if is_upgrade
            segment_info[:to].pmap do |entry|
              pid = entry[:pid]
              to_project = client&.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")
              to_blueprint = to_project&.blueprint(include_ca: true)
              is_upgrade, update_all, upgrade_datasets = blueprint_upgrade(latest_blueprint, to_blueprint)
              next unless is_upgrade

              message = get_upgrade_message(update_all, upgrade_datasets)

              results << {
                from: segment_info[:from],
                to: pid,
                status: to_project&.upgrade_custom_v2(message)
              }
            end
          end

          results
        end

        # Returns result compare between source blueprint and dest blueprint
        # @param project [GoodData::Model::ProjectBlueprint | Hash] Project blueprint
        # - First value return:
        #     true or false: the source blueprint need to run upgrade or not
        # - Second value return:
        #     true or false: the source blueprint run upgrade for all date dimensions or not
        # - Third value return: list of date dimensions dataset which be upgrade if it is not upgrade all
        def blueprint_upgrade(src_blueprint, dest_blueprint)
          dest_dates = get_date_dimensions(dest_blueprint) if dest_blueprint
          src_dates = get_date_dimensions(src_blueprint) if src_blueprint

          return false if dest_dates.empty? || src_dates.empty?

          upgrade_datasets = []
          dest_dates&.each do |dest|
            src_dim = get_date_dimension(src_blueprint, dest[:id])
            next unless src_dim

            upgrade_datasets << src_dim[:identifier] if upgrade?(src_dim, dest) && src_dim[:identifier]
          end

          [!upgrade_datasets.empty?, src_dates.length == upgrade_datasets.length, upgrade_datasets]
        end

        def get_upgrade_message(is_all, upgrade_datasets)
          if is_all
            {
              upgrade: {
                dateDatasets: {
                  upgrade: "all"
                }
              }
            }
          else
            {
              upgrade: {
                dateDatasets: {
                  upgrade: "exact",
                  datasets: upgrade_datasets
                }
              }
            }
          end
        end

        def upgrade?(src_dim, dest_dim)
          src_dim[:urn]&.include?(DATE_DIMENSION_CUSTOM_V2) && !dest_dim[:urn]&.include?(DATE_DIMENSION_CUSTOM_V2) && DATE_DIMENSION_OLD.any? { |e| dest_dim[:urn]&.include?(e) }
        end

        def get_date_dimension(blueprint, id)
          GoodData::Model::ProjectBlueprint.find_date_dimension(blueprint, id)
        end

        def get_date_dimensions(blueprint)
          GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)
        end
      end
    end
  end
end
