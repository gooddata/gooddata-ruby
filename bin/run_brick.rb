#!/usr/bin/env ruby

require 'remote_syslog_logger'

require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'
BRICK_PARAM_PREFIX = 'BRICK_PARAM_'
HIDDEN_BRICK_PARAMS_PREFIX = 'HIDDEN_BRICK_PARAM_'

brick_type = !ARGV.empty? ? ARGV[0] : DEFAULT_BRICK

def get_brick_params(prefix)
  ENV.select { |k,| k.to_s.match(/^#{prefix}.*/) }.map { |k, v| [k.slice(prefix.length..-1), v] }.to_h
end

syslog_node = ENV['NODE_NAME']
log = RemoteSyslogLogger.new(syslog_node, 514, :program => "ruby_#{brick_type}", :facility => 'local2')

log.info "action=#{brick_type}_execution status=init"

begin
  brick_pipeline = GoodData::Bricks::Pipeline.send("#{brick_type}_pipeline")
  normal_params = get_brick_params(BRICK_PARAM_PREFIX)
  hidden_params = get_brick_params(HIDDEN_BRICK_PARAMS_PREFIX)
  params = normal_params.merge(hidden_params)

  params['values_to_mask'] = hidden_params.values
  commit_hash = ENV['GOODDATA_RUBY_COMMIT'] || ''
  execution_id = ENV['GDC_EXECUTION_ID']
  params['gooddata_ruby_commit'] = commit_hash
  params['GDC_LOG_DIRECTORY'] = ENV['GDC_LOG_DIRECTORY'] || '/tmp/'
  params['GDC_EXECUTION_ID'] = execution_id
  log.info "action=#{brick_type}_execution status=start commit_hash=#{commit_hash} execution_id=#{execution_id}"
  brick_pipeline.call(params)
rescue Exception => e # rubocop:disable RescueException
	execution_log = GoodData.logger
	execution_log.error "Execution failed. Error: #{e}" unless execution_log.nil?
  log.info "action=#{brick_type}_execution status=failed commit_hash=#{commit_hash} execution_id=#{execution_id} exception=#{e}"
  raise
end
