# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class CollectUsersBrickUsers < BaseAction
      DESCRIPTION = 'Enriches parameters with users from the Users Brick input.'

      PARAMS = define_params(self) do
        description 'Input source of the Users Brick. Needed to prevent ' \
                    'deletion of filters for a user that is to be removed.'
        param :users_brick_config, instance_of(Type::UsersBrickConfig), required: true

        description 'Organization Name'
        param :organization, instance_of(Type::StringType), required: false

        description 'Domain'
        param :domain, instance_of(Type::StringType), required: false

        description 'Fail Early'
        param :fail_early, instance_of(Type::BooleanType), required: false

        description 'Strict'
        param :strict, instance_of(Type::BooleanType), required: false

        description 'Username'
        param :username, instance_of(Type::StringType), required: false

        description 'Password'
        param :password, instance_of(Type::StringType), required: false

        description 'Synchronization Mode (e.g. sync_one_project_based_on_pid)'
        param :sync_mode, instance_of(Type::StringType), required: false, default: 'sync_domain_and_project'

        description 'DataProduct to manage'
        param :data_product, instance_of(Type::GdProductType), required: false

        description 'Filters Config'
        param :filters_config, instance_of(Type::HashType), required: false

        description 'AWS Client'
        param :aws_client, instance_of(Type::GdSmartHashType), required: false

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: false

        description 'Development Client Used for Connecting to GD'
        param :development_client, instance_of(Type::GdClientType), required: false

        description 'GDC Project'
        param :gdc_project, instance_of(Type::GdProjectType), required: false

        description 'GDC Project Id'
        param :gdc_project_id, instance_of(Type::StringType), required: false

        description 'GDC client protocol'
        param :client_gdc_protocol, instance_of(Type::StringType), required: false

        description 'GDC client hostname'
        param :client_gdc_hostname, instance_of(Type::StringType), required: false

        description 'GDC password'
        param :gdc_password, instance_of(Type::StringType), required: false

        description 'GDC username'
        param :gdc_username, instance_of(Type::StringType), required: false

        description 'DataLogger'
        param :gdc_logger, instance_of(Type::GdLogger), required: false

        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: false

        description 'Segments filter'
        param :segments_filter, array_of(instance_of(Type::StringType)), required: false
      end

      class << self
        MODES = %w(
          add_to_organization
          sync_project
          sync_domain_and_project
          sync_multiple_projects_based_on_pid
          sync_one_project_based_on_pid
          sync_one_project_based_on_custom_id
          sync_multiple_projects_based_on_custom_id
          sync_domain_client_workspaces
        )

        def call(params)
          users_brick_users = []
          login_column = params.users_brick_config.login_column || 'login'
          users_brick_data_source = GoodData::Helpers::DataSource.new(params.users_brick_config.input_source)
          users_brick_data_source_file = File.open(
            users_brick_data_source.realize(params),
            'r:UTF-8'
          )
          CSV.foreach(users_brick_data_source_file,
                      headers: true,
                      return_headers: false,
                      encoding: 'utf-8') do |row|
            users_brick_users << { login: row[login_column] }
          end

          {
            results: users_brick_users,
            params: {
              users_brick_users: users_brick_users
            }
          }
        end
      end
    end
  end
end
