# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectClients < BaseAction
      DESCRIPTION = 'Collect Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Segments to manage'
        param :segments, array_of(instance_of(Type::SegmentType)), required: true

        description 'Client Id Column'
        param :client_id_column, instance_of(Type::StringType), required: false

        description 'Segment Id Column'
        param :segment_id_column, instance_of(Type::StringType), required: false

        description 'Project Id Column'
        param :project_id_column, instance_of(Type::StringType), required: false

        description 'Client Project Title Column'
        param :project_title_column, instance_of(Type::StringType), required: false

        description 'Client Project Token Column'
        param :project_token_column, instance_of(Type::StringType), required: false

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: true
      end

      RESULT_HEADER = [
        :client,
        :segment_id,
        :title
      ]

      class << self
        def call(params)
          segment_names = params.segments.map(&:segment_id)

          clients, errors = collect_clients(params, segment_names)
          fail "These are errors while collecting clients from input data:\n#{errors.join("\n")}" unless errors.empty?

          results = clients.map do |client|
            {
              client: client[:id],
              segment_id: client[:segment],
              title: client[:project_title]
            }
          end

          {
            results: results,
            params: {
              clients: clients
            }
          }
        end

        def collect_clients(params, segment_names = nil)
          client_id_column = params.client_id_column || 'client_id'
          segment_id_column = params.segment_id_column || 'segment_id'
          project_id_column = params.project_id_column || 'project_id'
          project_title_column = params.project_title_column || 'project_title'
          project_token_column = params.project_token_column || 'project_token'
          client = params.gdc_gd_client

          clients = []
          errors = []
          data_source = GoodData::Helpers::DataSource.new(params.input_source)
          input_data = File.open(data_source.realize(params), 'r:UTF-8')
          GoodData.logger.debug("Input data: #{input_data.read}")
          GoodData.logger.debug("Segment names: #{segment_names}")
          CSV.foreach(input_data, :headers => true, :return_headers => false, encoding: 'utf-8') do |row|
            GoodData.logger.debug("Processing row: #{row}")
            segment_name = row[segment_id_column]
            GoodData.logger.debug("Segment name: #{segment_name}")
            if segment_names.nil? || segment_names.include?(segment_name)
              client_id = row[client_id_column]
              pid = row[project_id_column]

              if pid
                begin
                  errors << "Project #{pid} of client #{client_id} is deleted." if client.projects(pid).deleted?
                rescue
                  errors << "Seems like you (user executing the script - #{client.user.login}) \
                  do not have access to project \"#{pid}\" of client \"#{client_id}\""
                end
              end

              clients << {
                id: client_id,
                segment: segment_name,
                project: pid,
                settings: [
                  {
                    name: 'lcm.token',
                    value: row[project_token_column]
                  },
                  {
                    name: 'lcm.title',
                    value: row[project_title_column]
                  }
                ]
              }.compact
            end
          end

          if clients.empty?
            errors << "No segments or clients qualify for provisioning. \
            Please check the input source data, platform segments, and the SEGMENTS_FILTER parameter. \
            The intersection of these three elements is empty set."
          end
          [clients, errors]
        end
      end
    end
  end
end
