#!/usr/bin/env ruby

require 'remote_syslog_logger'

require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'
BRICK_PARAM_PREFIX = 'BRICK_PARAM_'
HIDDEN_BRICK_PARAMS_PREFIX = 'HIDDEN_BRICK_PARAM_'

# MSF-17345 Set umask so files are group-writable
File.umask(0002)

brick_type = !ARGV.empty? ? ARGV[0] : DEFAULT_BRICK

def get_brick_params(prefix)
  ENV.select { |k,| k.to_s.match(/^#{prefix}.*/) }.map { |k, v| [k.slice(prefix.length..-1), v] }.to_h
end

def handle_error(params, log, brick_type, error, error_message)
  execution_log = GoodData.logger
  execution_log.error "Execution failed. Error: #{error}" unless execution_log.nil?
  GoodData::Bricks::ExecutionResultMiddleware.update_execution_result(GoodData::Bricks::ExecutionStatus::ERROR, error_message)
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
rescue GoodData::LcmExecutionError => lcm_error
  handle_error(execution_result_log_params, log, brick_type, lcm_error, lcm_error.summary_error)
rescue Exception => e # rubocop:disable RescueException
  handle_error(execution_result_log_params, log, brick_type, e, e.to_s)
end
