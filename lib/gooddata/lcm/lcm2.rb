# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'terminal-table'

require 'gooddata/extensions/class'
require 'gooddata/extensions/true'
require 'gooddata/extensions/false'
require 'gooddata/extensions/integer'
require 'gooddata/extensions/string'
require 'gooddata/extensions/nil'

require 'active_support/core_ext/hash/compact'

require_relative 'actions/actions'
require_relative 'dsl/dsl'
require_relative 'helpers/helpers'
require_relative 'exceptions/lcm_execution_error'

using TrueExtensions
using FalseExtensions
using IntegerExtensions
using StringExtensions
using NilExtensions

module GoodData
  module LCM2
    class SmartHash < Hash
      @specification = nil
      def method_missing(name, *_args)
        data(name)
      end

      def [](variable)
        data(variable)
      end

      def clear_filters
        @specification = nil
      end

      def setup_filters(filter)
        @specification = filter.to_hash
      end

      def check_specification(variable)
        if @specification && !@specification[variable.to_sym] && !@specification[variable.to_s] \
                          && !@specification[variable.to_s.downcase.to_sym] && !@specification[variable.to_s.downcase]
          fail "Param #{variable} is not defined in the specification"
        end
      end

      def data(variable)
        check_specification(variable)
        fetch(keys.find { |k| k.to_s.downcase.to_sym == variable.to_s.downcase.to_sym }, nil)
      end

      def key?(key)
        return true if super

        keys.each do |k|
          return true if k.to_s.downcase.to_sym == key.to_s.downcase.to_sym
        end

        false
      end

      def respond_to_missing?(name, *_args)
        key = name.to_s.downcase.to_sym
        key?(key)
      end
    end

    MODES = {

      hello: [
        HelloWorld
      ],

      help: [
        Help
      ],

      release: [
        EnsureReleaseTable,
        CollectDataProduct,
        SegmentsFilter,
        CreateSegmentMasters,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
        CollectLdmObjects,
        CollectMeta,
        CollectTaggedObjects,
        CollectComputedAttributeMetrics,
        ImportObjectCollections,
        SynchronizeComputedAttributes,
        SynchronizeProcesses,
        SynchronizeSchedules,
        SynchronizeColorPalette,
        SynchronizeUserGroups,
        SynchronizeNewSegments,
        UpdateReleaseTable
      ],

      release_set_master_project: [
        EnsureReleaseTable,
        CollectDataProduct,
        SegmentsFilter,
        SetMasterProject,
        UpdateReleaseTable
      ],

      provision: [
        EnsureReleaseTable,
        CollectDataProduct,
        CollectSegments,
        CollectClientProjects,
        PurgeClients,
        CollectClients,
        AssociateClients,
        RenameExistingClientProjects,
        ProvisionClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        CollectDymanicScheduleParams,
        SynchronizeETLsInSegment
      ],

      rollout: [
        EnsureReleaseTable,
        CollectDataProduct,
        CollectSegments,
        CollectSegmentClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
        MigrateGdcDateDimension,
        SynchronizeClients,
        SynchronizeComputedAttributes,
        CollectDymanicScheduleParams,
        SynchronizeETLsInSegment
      ],

      users: [
        CollectDataProduct,
        CollectMultipleProjectsColumn,
        CollectSegments,
        SynchronizeUsers
      ],

      user_filters: [
        CollectDataProduct,
        CollectMultipleProjectsColumn,
        CollectUsersBrickUsers,
        CollectSegments,
        SynchronizeUserFilters
      ],

      schedules_execution: [
        ExecuteSchedules
      ]

    }

    MODE_NAMES = MODES.keys

    class << self
      def convert_params(params)
        # Symbolize all keys
        GoodData::Helpers.symbolize_keys!(params)
        params.keys.each do |k|
          params[k.downcase] = params[k]
        end
        params.reject! do |k, _|
          k.downcase != k
        end
        convert_to_smart_hash(params)
      end

      def convert_to_smart_hash(params)
        if params.is_a?(Hash)
          res = SmartHash.new
          params.each_pair do |k, v|
            if v.is_a?(Hash) || v.is_a?(Array)
              res[k] = convert_to_smart_hash(v)
            else
              res[k] = v
            end
          end
          res
        elsif params.is_a?(Array)
          params.map do |item|
            convert_to_smart_hash(item)
          end
        else
          params
        end
      end

      def get_mode_actions(mode)
        mode = mode.to_sym
        actions = MODES[mode]
        if mode == :generic_lifecycle
          []
        else
          actions || fail("Invalid mode specified '#{mode}', supported modes are: '#{MODE_NAMES.join(', ')}'")
        end
      end

      def print_action_names(mode, actions)
        title = "Actions to be performed for mode '#{mode}'"

        headings = %w(# NAME DESCRIPTION)

        rows = []
        actions.each_with_index do |action, index|
          rows << [index, action.short_name, action.const_defined?(:DESCRIPTION) && action.const_get(:DESCRIPTION)]
        end

        table = Terminal::Table.new :title => title, :headings => headings do |t|
          rows.each_with_index do |row, index|
            t << row
            t.add_separator if index < rows.length - 1
          end
        end
        GoodData.logger.info("\n#{table}")
      end

      def print_action_result(action, messages)
        title = "Result of #{action.short_name}"

        keys = if action.const_defined?('RESULT_HEADER')
                 action.const_get('RESULT_HEADER')
               else
                 GoodData.logger.warn("Action #{action.name} does not have RESULT_HEADERS, inferring headers from results.")
                 (messages.first && messages.first.keys) || []
               end

        headings = keys.map(&:upcase)

        rows = messages && messages.map do |message|
          unless message
            GoodData.logger.warn("Found an empty message in the results of the #{action.name} action")
            next
          end
          row = []
          keys.each do |heading|
            row << message[heading]
          end
          row
        end

        rows ||= []
        rows.compact!

        table = Terminal::Table.new :title => title, :headings => headings do |t|
          rows.each_with_index do |row, index|
            t << (row || [])
            t.add_separator if index < rows.length - 1
          end
        end

        GoodData.logger.info("\n#{table}")
      end

      def print_actions_result(actions, results)
        actions.each_with_index do |action, index|
          print_action_result(action, results[index])
          GoodData.logger.info
        end
        nil
      end

      def perform(mode, params = {})
        params = convert_params(params)

        GoodData.gd_logger.brick = mode

        final_mode = if params.set_master_project && mode == 'release'
                       'release_set_master_project'
                     else
                       mode
                     end

        # Get actions for mode specified
        actions = get_mode_actions(final_mode)

        if params.actions
          actions = params.actions.map do |action|
            "GoodData::LCM2::#{action}".split('::').inject(Object) do |o, c|
              begin
                o.const_get(c)
              rescue NameError
                fail NameError, "Cannot find action 'GoodData::LCM2::#{action}'"
              end
            end
          end
        end

        # TODO: Check all action params first

        fail_early = if params.key?(:fail_early)
                       params.fail_early.to_b
                     else
                       true
                     end

        strict_mode = if params.key?(:strict)
                        params.strict.to_b
                      else
                        true
                      end

        skip_actions = (params.skip_actions || [])
        actions = actions.reject do |action|
          skip_actions.include?(action.name.split('::').last)
        end

        sync_mode = params.fetch(:sync_mode, nil)
        if mode == 'users' && %w[add_to_organization remove_from_organization].include?(sync_mode)
          actions = actions.reject do |action|
            %w[CollectDataProduct CollectSegments].include?(action.name.split('::').last)
          end
        end
        check_unused_params(actions, params)
        print_action_names(mode, actions)

        # Run actions
        errors = []
        results = []
        actions.each do |action|
          GoodData.logger.info("\n")
          # Invoke action
          begin
            out = run_action action, params
          rescue Exception => e # rubocop:disable RescueException
            errors << {
              action: action,
              err: e,
              backtrace: e.backtrace
            }
            break if fail_early
            results << nil
          end

          # in case fail_early = false, we need to execute another action
          next unless out

          # Handle output results and params
          res = out.is_a?(Array) ? out : out[:results]
          out_params = out.is_a?(Hash) ? out[:params] || {} : {}
          new_params = convert_to_smart_hash(out_params)

          # Merge with new params
          params.merge!(new_params)

          # Print action result
          print_action_result(action, res)

          # Store result for final summary
          results << res
        end

        brick_results = {}
        actions.each_with_index do |action, index|
          brick_results[action.short_name] = results[index]
        end

        result = {
          actions: actions.map(&:short_name),
          results: brick_results,
          params: params,
          success: errors.empty?
        }

        if errors.any?
          error_message = JSON.pretty_generate(errors)
          if strict_mode
            raise GoodData::LcmExecutionError.new(errors[0][:err], error_message)
          else
            GoodData.logger.error(error_message)
          end
        end

        result
      end

      def run_action(action, params)
        begin
          GoodData.gd_logger.start_action action, GoodData.gd_logger
          GoodData.gd_logger.info("Running #{action.name} action ...")
          params.clear_filters
          # Check if all required parameters were passed
          BaseAction.check_params(action.const_get('PARAMS'), params)
          params.setup_filters(action.const_get('PARAMS'))
          out = action.send(:call, params)
        ensure
          params.clear_filters
          GoodData.gd_logger.end_action GoodData.gd_logger
        end
        out
      end

      def check_unused_params(actions, params)
        default_params = [
          :client_gdc_hostname,
          :client_gdc_protocol,
          :fail_early,
          :gdc_logger,
          :gdc_password,
          :gdc_username,
          :strict
        ]

        action_params = actions.map do |action|
          action.const_get(:PARAMS).keys.map(&:downcase)
        end

        action_params.flatten!.uniq!

        param_names = params.keys.map(&:downcase)

        unused_params = param_names - (action_params + default_params)

        if unused_params.any?
          GoodData.logger.warn("Following params are not used by any action: #{JSON.pretty_generate(unused_params)}")

          rows = []
          actions.each do |action|
            action_params = action.const_get(:PARAMS)
            action_params.each do |_k, v|
              rows << [action.short_name, v[:name], v[:description], v[:type].class.short_name]
            end
          end

          table = Terminal::Table.new :headings => ['Action', 'Parameter', 'Description', 'Parameter Type'], :rows => rows
          GoodData.logger.info("\n#{table}")
        end
      end
    end
  end
end
