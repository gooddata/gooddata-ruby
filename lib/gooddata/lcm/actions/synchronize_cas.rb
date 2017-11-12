# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class SynchronizeComputedAttributes < BaseAction
      DESCRIPTION = 'Synchronize Computed Attributes'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Synchronization Info'
        param :synchronize, array_of(instance_of(Type::SynchronizationInfoType)), required: true, generated: true

        description 'Specifies whether to transfer computed attributes'
        param :include_computed_attributes, instance_of(Type::BooleanType), required: false, default: true
      end

      class << self
        def call(params)
          # set default value for include_computed_attributes
          # (we won't have to do this after TMA-690)
          include_ca = params.include_computed_attributes
          include_ca = true if include_ca.nil?
          include_ca = include_ca.to_b

          results = []
          return results unless include_ca

          client = params.gdc_gd_client

          params.synchronize.each do |info|
            from = info.from
            to_projects = info.to

            params.gdc_logger.info "Synchronize Computed Attributes from project pid: #{from}"

            to_projects.peach do |entry|
              ca_scripts = entry[:ca_scripts]
              next unless ca_scripts

              pid = entry[:pid]
              ca_chunks = ca_scripts['maqlDdlChunks']
              to_project = client.projects(pid) || fail("Invalid 'to' project specified - '#{pid}'")
              params.gdc_logger.info "Synchronizing Computed Attributes to project: '#{to_project.title}', PID: #{pid}"

              begin
                ca_chunks.each { |chunk| to_project.execute_maql(chunk) }
              rescue => e
                raise "Error occured when executing MAQL, project: \"#{to_project.title}\" reason: \"#{e.message}\", chunks: #{ca_chunks.inspect}"
              end

              results << {
                from: from,
                to: pid,
                status: 'ok'
              }
            end
          end

          results
        end
      end
    end
  end
end
