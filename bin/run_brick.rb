#!/usr/bin/env ruby

require 'remote_syslog_logger'

require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'
BRICK_PARAM_PREFIX = 'BRICK_PARAM_'
HIDDEN_BRICK_PARAMS_PREFIX = 'HIDDEN_BRICK_PARAM_'

brick_type = !ARGV.empty? ? ARGV[0] : DEFAULT_BRICK

module ExecutionStatus
  OK = 'OK'
  ERROR = 'ERROR'
end

def get_brick_params(prefix)
  ENV.select { |k,| k.to_s.match(/^#{prefix}.*/) }.map { |k, v| [k.slice(prefix.length..-1), v] }.to_h
end

def update_execution_result(params, log, brick_type, status, message)
  result = {
    executionResult: {
      status: status,
      message: message
    }
  }

  begin
    log_directory = params['GDC_LOG_DIRECTORY']
    execution_id = params['GDC_EXECUTION_ID']
    execution_result_logger_file = params['GDC_EXECUTION_RESULT_LOG_PATH'].nil? ? "#{log_directory}/#{execution_id}_result.json" : params['GDC_EXECUTION_RESULT_LOG_PATH']
    File.open(execution_result_logger_file, 'w') { |file| file.write(JSON.pretty_generate(result)) }
  rescue Exception => e # rubocop:disable RescueException
    log.warn "action=log_#{brick_type}_result execution_id=#{execution_id} status=failed exception=#{e}"
  end
end

def handle_error(params, log, brick_type, error, error_message)
  execution_log = GoodData.logger
  execution_log.error "Execution failed. Error: #{error}" unless execution_log.nil?
  update_execution_result(params, log, brick_type, ExecutionStatus::ERROR, error_message)
  log.error "action=#{brick_type}_execution status=failed commit_hash=#{params['GOODDATA_RUBY_COMMIT']} execution_id=#{params['GDC_EXECUTION_ID']} exception=#{error}"
  raise
end

syslog_node = ENV['NODE_NAME']
log = RemoteSyslogLogger.new(syslog_node, 514, :program => "ruby_#{brick_type}", :facility => 'local2')

log.info "action=#{brick_type}_execution status=init"

begin
  commit_hash = ENV['GOODDATA_RUBY_COMMIT'] || ''
  execution_id = ENV['GDC_EXECUTION_ID']
  log_directory = ENV['GDC_LOG_DIRECTORY'] || '/tmp/'
  execution_log_path = ENV['GDC_EXECUTION_LOG_PATH']
  execution_result_log_path = ENV['GDC_EXECUTION_RESULT_LOG_PATH']
  execution_result_log_params = {
    'GOODDATA_RUBY_COMMIT' => commit_hash,
    'GDC_EXECUTION_ID' => execution_id,
    'GDC_LOG_DIRECTORY' => log_directory,
    'GDC_EXECUTION_LOG_PATH' => execution_log_path,
    'GDC_EXECUTION_RESULT_LOG_PATH' => execution_result_log_path
  }

  brick_pipeline = GoodData::Bricks::Pipeline.send("#{brick_type}_pipeline")
  normal_params = get_brick_params(BRICK_PARAM_PREFIX)
  hidden_params = get_brick_params(HIDDEN_BRICK_PARAMS_PREFIX)
  params = normal_params.merge(hidden_params)

  params['values_to_mask'] = hidden_params.values
  params['gooddata_ruby_commit'] = commit_hash
  params['GDC_LOG_DIRECTORY'] = log_directory
  params['GDC_EXECUTION_ID'] = execution_id
  params['GDC_EXECUTION_LOG_PATH'] = execution_log_path
  params['GDC_EXECUTION_RESULT_LOG_PATH'] = execution_result_log_path

  log.info "action=#{brick_type}_execution status=start commit_hash=#{commit_hash} execution_id=#{execution_id}"
  brick_pipeline.call(params)
  update_execution_result(execution_result_log_params, log, brick_type, ExecutionStatus::OK, '')
rescue GoodData::LcmExecutionError => lcm_error
	handle_error(execution_result_log_params, log, brick_type, lcm_error, lcm_error.summary_error)
rescue Exception => e # rubocop:disable RescueException
  handle_error(execution_result_log_params, log, brick_type, e, e.to_s)
end
