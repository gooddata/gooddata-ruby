# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'
require 'thread_safe'

module GoodData
  module LCM2
    class SynchronizeUsers < BaseAction
      DESCRIPTION = 'Synchronizes Users Between Projects'

      PARAMS = define_params(self) do
        description 'Client Used For Connecting To GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'Input Source'
        param :input_source, instance_of(Type::HashType), required: true

        description 'Synchronization Mode (e.g. sync_one_project_based_on_pid)'
        param :sync_mode, instance_of(Type::StringType), required: false, default: 'sync_domain_and_project'

        description 'Column That Contains Target Project IDs'
        param :multiple_projects_column, instance_of(Type::StringType), required: false

        # gdc_project/gdc_project_id, required: true
        # organization/domain, required: true
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

        def version
          '0.0.1'
        end

        def call(params)
          client = params.gdc_gd_client
          domain_name = params.organization || params.domain
          project = client.projects(params.gdc_project) || client.projects(params.gdc_project_id)
          data_source = GoodData::Helpers::DataSource.new(params.input_source)
          mode = params.sync_mode
          unless mode.nil? || MODES.include?(mode)
            fail "The parameter \"sync_mode\" has to have one of the values #{MODES.map(&:to_s).join(', ')} or has to be empty."
          end

          whitelists = Set.new(params.whitelists || []) + Set.new((params.regexp_whitelists || []).map { |r| /#{r}/ }) + Set.new([client.user.login])

          multiple_projects_column = params.multiple_projects_column
          unless multiple_projects_column
            client_modes = %w(sync_domain_client_workspaces sync_one_project_based_on_custom_id sync_multiple_projects_based_on_custom_id)
            multiple_projects_column = if client_modes.include?(mode)
                                         'client_id'
                                       else
                                         'project_id'
                                       end
          end

          # Check mandatory columns and parameters
          mandatory_params = [domain_name, data_source]

          mandatory_params.each do |param|
            fail param + ' is required in the block parameters.' unless param
          end

          domain = client.domain(domain_name)

          first_name_column           = params.first_name_column || 'first_name'
          last_name_column            = params.last_name_column || 'last_name'
          login_column                = params.login_column || 'login'
          password_column             = params.password_column || 'password'
          email_column                = params.email_column || 'email'
          role_column                 = params.role_column || 'role'
          sso_provider_column         = params.sso_provider_column || 'sso_provider'
          authentication_modes_column = params.authentication_modes_column || 'authentication_modes'
          user_groups_column          = params.user_groups_column || 'user_groups'
          language_column             = params.language_column || 'language'
          company_column              = params.company_column || 'company'
          position_column             = params.position_column || 'position'
          country_column              = params.country_column || 'country'
          phone_column                = params.phone_column || 'phone'
          ip_whitelist_column         = params.ip_whitelist_column || 'ip_whitelist'

          sso_provider = params.sso_provider
          authentication_modes = params.authentication_modes || []
          ignore_failures = GoodData::Helpers.to_boolean(params.ignore_failures)
          remove_users_from_project = GoodData::Helpers.to_boolean(params.remove_users_from_project)
          do_not_touch_users_that_are_not_mentioned = GoodData::Helpers.to_boolean(params.do_not_touch_users_that_are_not_mentioned)
          create_non_existing_user_groups = GoodData::Helpers.to_boolean(params.create_non_existing_user_groups || true)

          new_users = []

          # params.delete('GDC_SST')

          data = nil
          dwh = params.ads_client
          if dwh
            data = dwh.execute_select(params.input_source.query)
          else
            tmp = File.open(data_source.realize(params), 'r:UTF-8')
            data = CSV.read(tmp, headers: true)
          end

          data.each do |row|
            params.gdc_logger.debug("Processing row: #{row}")

            modes = if authentication_modes.empty?
                      row[authentication_modes_column] || row[authentication_modes_column.to_sym] || []
                    else
                      authentication_modes
                    end

            modes = modes.split(',').map(&:strip).map { |x| x.to_s.upcase } unless modes.is_a? Array

            user_group = row[user_groups_column] || row[user_groups_column.to_sym]
            user_group = user_group.split(',').map(&:strip) if user_group

            ip_whitelist = row[ip_whitelist_column] || row[ip_whitelist_column.to_sym]
            ip_whitelist = ip_whitelist.split(',').map(&:strip) if ip_whitelist

            new_users << {
              :first_name => row[first_name_column] || row[first_name_column.to_sym],
              :last_name => row[last_name_column] || row[last_name_column.to_sym],
              :login => row[login_column] || row[login_column.to_sym],
              :password => row[password_column] || row[password_column.to_sym],
              :email => row[email_column] || row[login_column] || row[email_column.to_sym] || row[login_column.to_sym],
              :role => row[role_column] || row[role_column.to_sym],
              :sso_provider => sso_provider || row[sso_provider_column] || row[sso_provider_column.to_sym],
              :authentication_modes => modes,
              :user_group => user_group,
              :pid => multiple_projects_column.nil? ? nil : (row[multiple_projects_column] || row[multiple_projects_column.to_sym]),
              :language => row[language_column] || row[language_column.to_sym],
              :company => row[company_column] || row[company_column.to_sym],
              :position => row[position_column] || row[position_column.to_sym],
              :country => row[country_column] || row[country_column.to_sym],
              :phone => row[phone_column] || row[phone_column.to_sym],
              :ip_whitelist => ip_whitelist
            }.compact
          end

          semaphore = Mutex.new

          params.gdc_logger.info("Synchronizing in mode \"#{mode}\"")

          # There are several scenarios we want to provide with this brick
          # 1) Sync only domain
          # 2) Sync both domain and project
          # 3) Sync multiple projects. Sync them by using one file. The file has to
          #     contain additional column that contains the PID of the project so the
          #     process can partition the users correctly. The column is configurable
          # 4) Sync one project the users are filtered based on a column in the data
          #     that should contain pid of the project
          # 5) Sync one project. The users are filtered form a given file based on the
          #     value in the file. The value is compared against the value
          #     GOODOT_CUSTOM_PROJECT_ID that is saved in project metadata. This is
          #     aiming at solving the problem that the customer cannot give us the
          #     value of a project id in the data since he does not know it upfront
          #     and we cannot influence its value.
          results = case mode
                    when 'add_to_organization'
                      domain.create_users(new_users.uniq { |u| u[:login] || u[:email] })
                    when 'sync_project'
                      project.import_users(new_users,
                                           domain: domain,
                                           whitelists: whitelists,
                                           ignore_failures: ignore_failures,
                                           remove_users_from_project: remove_users_from_project,
                                           do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned,
                                           create_non_existing_user_groups: create_non_existing_user_groups)
                    when 'sync_multiple_projects_based_on_pid'
                      new_users.group_by { |user| user[:pid] }.flat_pmap do |project_id, users|
                        begin
                          client_project = client.projects(project_id)
                          fail "You (user executing the script - #{client.user.login}) is not admin in project \"#{project_id}\"." unless client_project.am_i_admin?
                          client_project.import_users(users,
                                                      domain: domain,
                                                      whitelists: whitelists,
                                                      ignore_failures: ignore_failures,
                                                      remove_users_from_project: remove_users_from_project,
                                                      do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned)
                        rescue RestClient::ResourceNotFound
                          fail "Project \"#{project_id}\" was not found. Please check your project ids in the source file"
                        rescue RestClient::Gone
                          fail "Seems like you (user executing the script - #{client.user.login}) do not have access to project \"#{project_id}\""
                        rescue RestClient::Forbidden
                          fail "User #{client.user.login} is not enabled within project \"#{project_id}\""
                        end
                      end
                    when 'sync_one_project_based_on_pid'
                      filtered_users = new_users.select { |u| u[:pid] == project.pid }
                      project.import_users(filtered_users,
                                           domain: domain,
                                           whitelists: whitelists,
                                           ignore_failures: ignore_failures,
                                           remove_users_from_project: remove_users_from_project,
                                           do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned,
                                           create_non_existing_user_groups: create_non_existing_user_groups)
                    when 'sync_one_project_based_on_custom_id'
                      md = project.metadata
                      goodot_id = md['GOODOT_CUSTOM_PROJECT_ID'].to_s

                      filtered_users = new_users.select do |u|
                        fail "Column for determining the project assignement is empty for \"#{u[:login]}\"" if u[:pid].blank?
                        client_id = u[:pid].to_s
                        (goodot_id && client_id == goodot_id) || domain.clients(client_id).project_uri == project.uri
                      end

                      if filtered_users.empty?
                        fail "Project \"#{project.pid}\" does not match with any client ids in input source (both GOODOT_CUSTOM_PROJECT_ID and SEGMENT/CLIENT). \
  We are unable to get the value to filter users."
                      end

                      params.gdc_logger.info("Project #{project.pid} will receive #{filtered_users.count} from #{new_users.count} users")
                      project.import_users(filtered_users,
                                           domain: domain,
                                           whitelists: whitelists,
                                           ignore_failures: ignore_failures,
                                           remove_users_from_project: remove_users_from_project,
                                           do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned,
                                           create_non_existing_user_groups: create_non_existing_user_groups)
                    when 'sync_multiple_projects_based_on_custom_id'
                      new_users.group_by { |user| user[:pid] }.flat_pmap do |client_id, users|
                        fail "Client id cannot be empty" if client_id.blank?
                        client_project = domain.clients(client_id).project
                        fail "Client #{client_id} does not have project." unless client_project
                        semaphore.synchronize { params.gdc_logger.info("Project #{client_project.pid} of client #{client_id} will receive #{users.count} users") }
                        client_project.import_users(users,
                                                    domain: domain,
                                                    whitelists: whitelists,
                                                    ignore_failures: ignore_failures,
                                                    remove_users_from_project: remove_users_from_project,
                                                    do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned)
                      end
                    when 'sync_domain_client_workspaces'
                      domain_clients = domain.clients
                      if params.segments_filter
                        segments_filter = params.segments_filter.map { |seg| "/gdc/domains/#{domain.name}/segments/#{seg}" }
                        domain_clients.select! { |c| segments_filter.include?(c.segment_uri) }
                      end
                      working_client_ids = ThreadSafe::Array.new
                      res = ThreadSafe::Array.new
                      res += new_users.group_by { |user| user[:pid] }.flat_pmap do |client_id, users|
                        fail "Client id cannot be empty" if client_id.blank?
                        segment_client = domain_clients.find { |domain_client| domain_client.client_id.to_s == client_id.to_s }
                        if params.segments_filter && !segments_filter.include?(segment_client.segment_uri)
                          semaphore.synchronize { params.gdc_logger.warn("Client #{client_id} is outside segments_filter #{params.segments_filter}") }
                          next
                        end
                        client_project = segment_client.project
                        fail "Client #{client_id} does not have project." unless client_project
                        working_client_ids << client_id.to_s
                        semaphore.synchronize { params.gdc_logger.info("Project #{client_project.pid} of client #{client_id} will receive #{users.count} users") }
                        client_project.import_users(users,
                                                    domain: domain,
                                                    whitelists: whitelists,
                                                    ignore_failures: ignore_failures,
                                                    remove_users_from_project: remove_users_from_project,
                                                    do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned)
                      end

                      params.gdc_logger.debug("Working client ids are: #{working_client_ids.join(', ')}")

                      unless do_not_touch_users_that_are_not_mentioned
                        domain_clients.peach do |domain_client|
                          next if working_client_ids.include?(domain_client.client_id.to_s)
                          begin
                            clean_up_project = domain_client.project
                          rescue => e
                            semaphore.synchronize { params.gdc_logger.warn("Error when accessing project of client #{domain_client.client_id}. Error: #{e}") }
                            next
                          end
                          unless clean_up_project
                            semaphore.synchronize { params.gdc_logger.warn("Client #{domain_client.client_id} has no project.") }
                            next
                          end
                          if clean_up_project.deleted?
                            semaphore.synchronize { params.gdc_logger.warn("Project #{clean_up_project.pid} of client #{domain_client.client_id} is deleted.") }
                            next
                          end
                          semaphore.synchronize { params.gdc_logger.info("Synchronizing all users in project #{clean_up_project.pid} of client #{domain_client.client_id}") }
                          res += clean_up_project.import_users([],
                                                               domain: domain,
                                                               whitelists: whitelists,
                                                               ignore_failures: ignore_failures,
                                                               remove_users_from_project: remove_users_from_project,
                                                               do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned)
                        end
                      end

                      res
                    else
                      domain.create_users(new_users, ignore_failures: ignore_failures)
                      project.import_users(new_users,
                                           domain: domain,
                                           whitelists: whitelists,
                                           ignore_failures: ignore_failures,
                                           remove_users_from_project: remove_users_from_project,
                                           do_not_touch_users_that_are_not_mentioned: do_not_touch_users_that_are_not_mentioned,
                                           create_non_existing_user_groups: create_non_existing_user_groups)
                    end

          results.compact!
          counts = results.group_by { |r| r[:type] }.map { |g, r| [g, r.count] }
          counts.each do |category, count|
            params.gdc_logger.info("There were #{count} events of type #{category}")
          end
          errors = results.select { |r| r[:type] == :error || r[:type] == :failed }
          return if errors.empty?

          params.gdc_logger.info("Printing 10 first errors")
          params.gdc_logger.info("========================")
          pp errors.take(10)
          fail 'There was an error syncing users'
        end
      end
    end
  end
end
