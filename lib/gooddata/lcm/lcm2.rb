# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'terminal-table'

require_relative 'actions/actions'
require_relative 'dsl/dsl'
require_relative 'helpers/helpers'

module GoodData
  module LCM2
    class SmartHash < Hash
      def method_missing(name, *_args)
        key = name.to_s.downcase.to_sym

        if key?(key)
          self[key]
        else
          begin
            super
          rescue
            nil
          end
        end
      end

      def respond_to_missing?(name, *_args)
        key = name.to_s.downcase.to_sym
        key?(key)
      end
    end

    MODES = {
      # Low Level Commands

      actions: [
        PrintActions
      ],

      hello: [
        HelloWorld
      ],

      modes: [
        PrintModes
      ],

      info: [
        PrintTypes,
        PrintActions,
        PrintModes
      ],

      types: [
        PrintTypes
      ],

      ## Bricks

      release: [
        EnsureReleaseTable,
        SegmentsFilter,
        CreateSegmentMasters,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
        SynchronizeMeta,
        SynchronizeAttributeDrillpath,
        SynchronizeProcesses,
        SynchronizeSchedules,
        SynchronizeColorPalette,
        SynchronizeNewSegments,
        UpdateReleaseTable
      ],

      provision: [
        EnsureReleaseTable,
        CollectSegments,
        SegmentsFilter,
        PurgeClients,
        CollectClients,
        AssociateClients,
        ProvisionClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        EnsureTitles,
        SynchronizeAttributeDrillpath,
        SynchronizeProcesses,
        SynchronizeSchedules
      ],

      rollout: [
        EnsureReleaseTable,
        CollectSegments,
        SegmentsFilter,
        CollectSegmentClients,
        EnsureTechnicalUsersDomain,
        EnsureTechnicalUsersProject,
        SynchronizeLdm,
#        SynchronizeLabelTypes,
        SynchronizeAttributeDrillpath,
        SynchronizeProcesses,
        SynchronizeSchedules,
        SynchronizeClients
      ]
    }

    MODE_NAMES = MODES.keys

    class << self
      def convert_params(params)
        # Symbolize all keys
        GoodData::Helpers.symbolize_keys!(params)
        convert_to_smart_hash(params)
      end

      def convert_to_smart_hash(params)
        if params.is_a?(Hash)
          res = SmartHash.new
          params.each_pair do |k, v|
            if v.is_a?(Hash) || v.is_a?(Array)
              res[k.downcase] = convert_to_smart_hash(v)
            else
              res[k.downcase] = v
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
        MODES[mode.to_sym] || fail("Invalid mode specified '#{mode}', supported modes are: '#{MODE_NAMES.join(', ')}'")
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
        puts "\n#{table}"
      end

      def print_action_result(action, messages)
        title = "Result of #{action.short_name}"

        keys = if action.const_defined?('RESULT_HEADER')
                 action.const_get('RESULT_HEADER')
               else
                 (messages.first && messages.first.keys) || []
               end

        headings = keys.map(&:upcase)

        rows = messages.map do |message|
          row = []
          keys.each do |heading|
            row << message[heading]
          end
          row
        end

        table = Terminal::Table.new :title => title, :headings => headings do |t|
          rows.each_with_index do |row, index|
            t << row
            t.add_separator if index < rows.length - 1
          end
        end

        puts "\n#{table}"
      end

      def print_actions_result(actions, results)
        actions.each_with_index do |action, index|
          print_action_result(action, results[index])
          puts
        end
        nil
      end

      def perform(mode, params = {})
        params = convert_params(params)

        # Get actions for mode specified
        actions = get_mode_actions(mode)

        # Print name of actions to be performed for debug purposes
        print_action_names(mode, actions)

        # TODO: Check all action params first

        new_params = params

        # Run actions
        results = actions.map do |action|
          puts

          # Invoke action
          out = action.send(:call, params)

          # Handle output results and params
          res = out.is_a?(Array) ? out : out[:results]
          out_params = out.is_a?(Hash) ? out[:params] || {} : {}
          new_params = convert_to_smart_hash(out_params)

          # Merge with new params
          params.merge!(new_params)

          # Print action result
          puts
          print_action_result(action, res)

          # Return result for final summary
          res
        end

        if actions.length > 1
          puts
          puts 'SUMMARY'
          puts

          # Print execution summary/results
          print_actions_result(actions, results)
        end

        brick_results = {}
        actions.each_with_index do |action, index|
          brick_results[action.class.short_name] = results[index]
        end

        {
          actions: actions.map do |action|
            action.class.short_name
          end,
          results: brick_results,
          params: params
        }
      end
    end
  end
end
