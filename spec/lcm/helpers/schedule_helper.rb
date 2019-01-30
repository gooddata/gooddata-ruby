module GoodData
  module AppStore
    module Helper
      class << self
        def wait_for_executions(schedules, timeout)
          start_time = Time.now
          schedules.map do |schedule|
            execution = wait_for_execution(
              schedule,
              remaining_time(start_time, timeout)
            )
            result = execution.wait_for_result(
              timeout: remaining_time(start_time, timeout)
            )
            puts result.log.body
            result
          end
        end

        private

        def wait_for_execution(schedule, timeout)
          start_time = Time.now
          until schedule.executions.any?
            puts 'Waiting for execution to begin.'
            elapsed_time = Time.now - start_time
            fail 'Timeout reached.' if elapsed_time > timeout

            sleep 1.minute
          end
          schedule.executions.first
        end

        def remaining_time(start_time, timeout)
          timeout - (Time.now - start_time)
        end
      end
    end
  end
end
