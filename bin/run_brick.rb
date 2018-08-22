#!/usr/bin/env ruby

require 'remote_syslog_logger'
require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'

brick_type = ENV['BRICK_TYPE'] || DEFAULT_BRICK

syslog_node = ENV['NODE_NAME']
log = RemoteSyslogLogger.new(syslog_node, 514, :program => brick_type)

log.info "action=#{brick_type}_execution status=start"

begin
  brick_pipeline = GoodData::Bricks::Pipeline.send("#{brick_type}_pipeline")
  params_json = ENV['BRICK_PARAMS_JSON']
  params = params_json.nil? ? {} : JSON.parse(params_json)

  params['gooddata_ruby_commit'] = ENV['GOODDATA_RUBY_COMMIT'] || '<unknown>'
  params['log_directory'] = ENV['LOG_DIRECTORY'] || '/tmp/'

  @brick_result = brick_pipeline.call(params)
  log.info "action=#{brick_type}_execution status=finished"
rescue NoMethodError => e
  log.info "action=#{brick_type}_execution status=error Invalid brick type '#{brick_type}', #{e.message}"
  raise e
rescue => e
  log.info "action=#{brick_type}_execution status=error #{e.message}"
  raise e
end
