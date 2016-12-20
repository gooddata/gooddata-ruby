# encoding: UTF-8
#
# Copyright (c) 2010-2016 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class AssociateClients < BaseAction
      DESCRIPTION = 'Associate LCM Clients'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true
      end

      class << self
        def call(params)
          # Check if all required parameters were passed
          BaseAction.check_params(PARAMS, params)

          client = params.gdc_gd_client

          delete_projects = (params.delete_projects == 'false' || params.delete_projects == false) ? false : true
          delete_extra = (params.delete_extra == 'false' || params.delete_extra == false) ? false : true

          domain_name = params.organization || params.domain
          domain = client.domain(domain_name) || fail("Invalid domain name specified - #{domain_name}")

          domain.update_clients(params.clients, delete_extra: delete_extra, delete_projects: delete_projects)
        end

        # Segment Workspace Association
        #
        # @param [GoodData::Client] client Client used for communication with platform
        # @param [GoodData::Domain] domain Domain to associate
        # @param [Hash] params Parameters
        # @option params [String] 'client_id_column' Name of column containing Client ID
        # @option params [String] 'segment_id_column' Name of column containing Segment ID
        # @option params [String] 'project_id_column' Name of column containing Project ID
        # @option params [String, nil] 'technical_client' (nil) Technical associations
        # @option params [String] 'deprovision' ('delete') What to do with de-provisioned projects - delete or disable
        # @option params [String] 's3_username' S3 Username
        # @option params [String] 's3_password' S3 Password
        # @option params [String] 's3_bucket' S3 Bucket
        # @option params [String] 's3_prefix' S3 Path Prefix
        def associate(clients, domain, params)
          delete_projects = (params.delete_projects == 'false' || params.delete_projects == false) ? false : true
          delete_extra = (params.delete_extra == 'false' || params.delete_extra == false) ? false : true

          # TODO: Implement
          # if params['s3_access_key_id'] && params['s3_secret_access_key'] && params['s3_bucket']
          #   aws_s3_backup(domain, params)
          # end

          # TODO: Implement
          # if params.key?('technical_client')
          #   technical_associtaions = [params['technical_client']].flatten(1)
          #   technical_associtaions.each do |ta|
          #     tas = GoodData::Helpers.symbolize_keys(ta)
          #     clients << {:id => tas[:client_id], :segment => tas[:segment_id]}
          #   end
          # end

          clients.each do |c|
            fail "Row does not contain client or segment information. Please fill it in or provide custom header information." if c[:segment].blank? || c[:id].blank?
          end

          domain.update_clients(clients, delete_extra: delete_extra, delete_projects: delete_projects)
            .map { |message| message.merge(type: :client_association) }
        end
      end
    end
  end
end
