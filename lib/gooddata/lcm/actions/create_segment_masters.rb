# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'multi_json'

require_relative 'base_action'

module GoodData
  module LCM2
    class CreateSegmentMasters < BaseAction
      DESCRIPTION = 'Create Master Projects for Segments'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: true

        description 'ADS Client'
        param :ads_client, instance_of(Type::AdsClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Tokens'
        param :tokens, instance_of(Type::TokensType), required: true

        description 'Table Name'
        param :release_table_name, instance_of(Type::StringType), required: false
      end

      DEFAULT_TABLE_NAME = 'LCM_RELEASE'

      class << self
        def call(params)
          results = []

          client = params.gdc_gd_client
          development_client = params.development_client

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")
          domain_segments = domain.segments

          # TODO: Support for 'per segment' provisioning
          segments = params.segments

          synchronize_projects = segments.map do |segment_in| # rubocop:disable Metrics/BlockLength
            segment_id = segment_in.segment_id
            development_pid = segment_in.development_pid
            driver = segment_in.driver.downcase
            token = params.tokens[driver.to_sym] || fail("Token for driver '#{driver}' was not specified")
            ads_output_stage_uri = segment_in.ads_output_stage_uri

            # Create master project Postgres
            version = get_project_version(params, segment_id) + 1

            master_name = segment_in.master_name.gsub('#{version}', version.to_s)

            # Get project instance based on PID. Fail if invalid one was specified.
            # TODO: Use development client for getting project
            development_client.projects(development_pid) || fail("Invalid Development PID specified - #{development_pid}")
            segment = domain_segments.find do |ds|
              ds.segment_id == segment_id
            end

            # Create new master project
            params.gdc_logger.info "Creating master project - name: '#{master_name}' development_project: '#{development_pid}', segment: '#{segment_id}', driver: '#{driver}'"
            project = client.create_project(title: master_name, auth_token: token, driver: driver == 'vertica' ? 'vertica' : 'Pg')

            # Does segment exists? If not, create new one and set initial master
            if segment
              segment_in[:is_new] = false
              status = 'untouched'
            else
              params.gdc_logger.info "Creating segment #{segment_id}, master #{project.pid}"
              segment = domain.create_segment(segment_id: segment_id, master_project: project)
              segment.synchronize_clients
              segment_in[:is_new] = true
              status = 'created'
            end

            master_project = nil

            begin
              master_project = segment.master_project
            rescue => e
              GoodData.logger.warn "Unable to get segment master, reason: #{e.message}"
            end

            if master_project.nil? || master_project.deleted?
              segment.master_project = project
              segment.save
              segment_in[:is_new] = true
              status = 'modified'
            end

            segment_in[:master_pid] = project.pid
            segment_in[:version] = version
            segment_in[:timestamp] = Time.now.utc.iso8601

            # Show new project
            params.gdc_logger.info MultiJson.dump(project.json, :pretty => true)

            # Add new segment master project with additional info into output results
            results << {
              segment_id: segment_id,
              name: master_name,
              development_pid: development_pid,
              master_pid: project.pid,
              ads_output_stage_uri: ads_output_stage_uri,
              driver: driver,
              status: status
            }

            {
              segment: segment_id,
              from: development_pid,
              to: [{ pid: project.pid }],
              ads_output_stage_uri: ads_output_stage_uri
            }
          end

          # Return results
          {
            results: results,
            params: {
              synchronize: synchronize_projects
            }
          }
        end

        def get_project_version(params, segment_id)
          replacements = {
            table_name: params.release_table_name || DEFAULT_TABLE_NAME,
            segment_id: segment_id
          }

          path = File.expand_path('../../data/select_from_lcm_release.sql.erb', __FILE__)
          query = GoodData::Helpers::ErbHelper.template_file(path, replacements)

          res = params.ads_client.execute_select(query)

          return 0 if res.empty?

          res[0][:version].to_i
        end
      end
    end
  end
end
