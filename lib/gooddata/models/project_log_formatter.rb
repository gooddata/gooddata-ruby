require_relative 'project'

module GoodData
  class ProjectLogFormatter
    def initialize(project)
      @project = project
    end

    # Log created users
    #
    # @param created_users [Array<Hash>] collection of created user result, e.g:
    # [
    #   {
    #     type => :successful || :failed,
    #     user => '/gdc/account/profile/abc@gooddata.com',
    #     message => error_message,
    #     reason: error_message
    #   },
    #   ...
    # ]
    # @param new_users [Array<Hash>] collection of new users to be created
    #   [
    #     {
    #       login => 'xxx@gooddata.com',
    #       role_title => 'Editor' || 'Admin' || ...
    #     },
    #     ...
    #   ]
    # @return nil
    def log_created_users(created_users, new_users)
      created_users.each do |created_user|
        user_login = to_user_login(created_user[:user])
        if created_user[:type] == :successful
          user_data = new_users.find { |new_user| new_user[:login] == user_login }
          GoodData.logger.info("Added new user=#{user_login}, roles=#{user_data[:role_title]} to project=#{@project.pid}.")
        elsif created_user[:type] == :failed
          error_message = created_user[:message] || created_user[:reason]
          GoodData.logger.error("Failed to add user=#{user_login} to project=#{@project.pid}. Error: #{error_message}")
        end
      end
    end

    # Log updated users
    #
    # @param updated_users [Array<Hash>] collection of updated user result, e.g:
    #   [
    #     {
    #       type => :successful || :failed,
    #       user => '/gdc/account/profile/abc@gooddata.com',
    #       message => error_message,
    #       reason: error_message
    #     },
    #     ...
    #   ]
    # @param changed_users [Array<Hash>] collection of changed users to be updated
    #   [
    #     {
    #       old_obj: {
    #         :login => '/gdc/account/profile/abc@gooddata.com',
    #         :role => '/gdc/projects/clp4z1qw60o0t048tov909b1xi4qztay/roles/5'
    #       },
    #       new_obj: {
    #         :role_title => 'Editor' || 'Admin' || ...
    #       }
    #     },
    #     ...
    #   ]
    # @param role_list [Array<ProjectRole>] project roles
    # @return nil
    def log_updated_users(updated_users, changed_users, role_list)
      updated_users.each do |updated_user|
        user_login = to_user_login(updated_user[:user])
        if updated_user[:type] == :successful
          changed_user = changed_users.find { |user| user[:old_obj][:login] == user_login }
          old_user_data = changed_user[:old_obj]
          old_role_uris = old_user_data[:role] || old_user_data[:roles]
          old_role_titles = old_role_uris.map do |old_role_uri|
            old_role = @project.get_role(old_role_uri, role_list)
            old_role && old_role.title
          end
          new_role_titles = changed_user[:new_obj][:role_title]
          GoodData.logger.info("Update user=#{user_login} from old_roles=#{old_role_titles} to new_roles=#{new_role_titles} in project=#{@project.pid}.")
        elsif updated_user[:type] == :failed
          error_message = updated_user[:message] || updated_user[:reason]
          GoodData.logger.error("Failed to update user=#{user_login} to project=#{@project.pid}. Error: #{error_message}")
        end
      end
    end

    # Log disabled users
    #
    # @param disabled_users [Array<Hash>] collection of disabled user result, e.g:
    #   [
    #     {
    #       type => :successful || :failed,
    #       user => '/gdc/account/profile/abc@gooddata.com',
    #       message => error_message,
    #       reason: error_message
    #     },
    #     ...
    #   ]
    # @return nil
    def log_disabled_users(disabled_users)
      disabled_users.each do |disabled_user|
        user_login = to_user_login(disabled_user[:user])
        if disabled_user[:type] == :successful
          GoodData.logger.warn("Disable user=#{user_login} in project=#{@project.pid}")
        elsif disabled_user[:type] == :failed
          error_message = disabled_user[:message] || disabled_user[:reason]
          GoodData.logger.error("Failed to disable user=#{user_login} in project=#{@project.pid}. Error: #{error_message}")
        end
      end
    end

    # Log removed users
    #
    # @param removed_users [Array<Hash>] collection of removed user result, e.g:
    #   [
    #     {
    #       type => :successful || :failed,
    #       user => {
    #         login => 'abc@gooddata.com'
    #       },
    #       message => error_message
    #     },
    #     ...
    #   ]
    # @return nil
    def log_removed_users(removed_users)
      removed_users.each do |removed_user|
        user_login = to_user_login(removed_user[:user])
        if removed_user[:type] == :successful
          GoodData.logger.warn("Remove user=#{user_login} out of project=#{@project.pid}")
        elsif removed_user[:type] == :failed
          error_message = removed_user[:message]
          GoodData.logger.error("Failed to remove user=#{user_login} out of project=#{@project.pid}. Error: #{error_message}")
        end
      end
    end

    # Log user filters results
    #
    # @param results [Array<Hash>] user-filter results
    # [
    #   {
    #     status: :successful || :failed,
    #     type: :create || delete,
    #     user: user_profile_url
    #   },
    #   ...
    # ]
    # @param user_filters [Hash] user-filters data
    # {
    #   user_profile_url => MandatoryUserFilter,
    #   ...
    # }
    # @return nil
    def log_user_filter_results(results, user_filters)
      results ||= []
      results.each do |result|
        user_profile_url = result[:user]
        status = result[:status]
        operator = result[:type]
        if status == :successful
          filter_uris = user_filters[user_profile_url].map(&:uri)
          if operator == :create && GoodData.logger.info?
            GoodData.logger.info "Created user-filter=#{filter_uris} for user=#{user_profile_url} in project=#{@project.pid}"
          elsif operator == :delete && GoodData.logger.warn?
            GoodData.logger.warn "Deleted user-filter=#{filter_uris} of user=#{user_profile_url} in project=#{@project.pid}"
          end
        else
          error_message = result[:message]
          if operator == :create && GoodData.logger.error?
            GoodData.logger.error "Failed to create user-filters for user=#{user_profile_url} in project=#{@project.pid}. Error: #{error_message}"
          elsif operator == :delete && GoodData.logger.error?
            GoodData.logger.error "Failed to delete user-filters from user=#{user_profile_url} in project=#{@project.pid}. Error: #{error_message}"
          end
        end
      end
    end

    private

    def to_user_login(user)
      if user.is_a?(String) && user.start_with?('/gdc/account/profile/')
        GoodData::Helpers.last_uri_part(user)
      elsif user.is_a?(Hash) && user[:login]
        user[:login]
      else
        user
      end
    end
  end
end
