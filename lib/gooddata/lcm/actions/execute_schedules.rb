# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'base_action'

module GoodData
  module LCM2
    class ExecuteSchedules < BaseAction
      DESCRIPTION = 'Execute schedules'

      PARAMS = define_params(self) do
        description 'Client Used for Connecting to GD'
        param :gdc_gd_client, instance_of(Type::GdClientType), required: true

        description 'List Of Modes'
        param :list_of_modes, instance_of(Type::StringType), required: true

        description 'Work Done Identificator'
        param :work_done_identificator, instance_of(Type::StringType), required: true

        description 'Number Of Schedules In Batch'
        param :number_of_schedules_in_batch, instance_of(Type::StringType), required: false, default: '1000'

        description 'Delay Between Batches'
        param :delay_between_batches, instance_of(Type::StringType), required: false, default: '0'

        description 'Control Parameter'
        param :control_parameter, instance_of(Type::StringType), required: false, default: 'MODE'

        description 'Wait For Schedule'
        param :wait_for_schedule, instance_of(Type::StringType), required: false, default: 'false'
      end

      class << self
        def call(params)
          logger = params.gdc_logger

          client = params.gdc_gd_client
          project = client.projects(params.gdc_project) || client.projects(params.gdc_project_id)

          list_of_modes = params.list_of_modes.split('|').map(&:strip)
          work_done_identificator = params.work_done_identificator
          number_of_schedules_in_batch = Integer(params.number_of_schedules_in_batch || "1000")
          delay_between_batches = Integer(params.delay_between_batches || "0")
          control_parameter = params.control_parameter || "MODE"
          wait = GoodData::Helpers.to_boolean(params.wait_for_schedule)

          # The WORK_DONE_IDENTIFICATOR is flag which tells the executor to execute the schedules
          # It could have special value IGNORE. In this case all corresponding schedules will be started during every run of this brick

          start_schedules = work_done_identificator == 'IGNORE' || GoodData::Helpers.to_boolean(project.metadata[work_done_identificator])

          if start_schedules
            schedules_to_filter = client.projects.pmapcat do |p|
              begin
                p.schedules
              rescue => e
                logger.info "The retrieval of project schedules, for project #{p.obj_id} has failed. Message: #{e.message}."
                []
              end
            end

            schedules_to_start = schedules_to_filter.select { |schedule| list_of_modes.include?(schedule.params[control_parameter]) }
            logger.info "Found #{schedules_to_start.count} schedules to execute"

            schedules_to_start.each_slice(number_of_schedules_in_batch).each_with_index do |batch_schedules, batch_index|
              batch_number = batch_index + 1
              logger.info "Starting batch number #{batch_number}. Number of schedules in batch #{batch_schedules.count}."
              batch_schedules.each do |schedule|
                begin
                  tries ||= 5
                  logger.info "Starting schedule for project #{schedule.project.pid} - #{schedule.project.title}. Schedule ID is #{schedule.obj_id}"
                  schedule.execute(wait: wait)
                rescue => e
                  if (tries -= 1) > 0
                    logger.warn "There was error during operation: #{e.message}. Retrying"
                    sleep(5)
                    retry
                  else
                    logger.info "We could not start schedule for project #{schedule.project.pid} - #{schedule.project.title} - #{e.message}"
                  end
                else
                  logger.info "Operation finished"
                end
              end
              logger.info "Entering sleep mode for #{delay_between_batches} seconds"
              sleep(delay_between_batches)
            end
            project.set_metadata(work_done_identificator, 'false') unless work_done_identificator == 'IGNORE'
          end
        end
      end
    end
  end
end
