#!/usr/bin/env ruby

require 'remote_syslog_logger'
require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'
BRICK_PARAM_PREFIX = 'BRICK_PARAM_'

brick_type = !ARGV.empty? ? ARGV[0] : DEFAULT_BRICK

syslog_node = ENV['NODE_NAME']
log = RemoteSyslogLogger.new(syslog_node, 514, :program => "ruby_#{brick_type}", :facility => 'local2')

log.info "action=#{brick_type}_execution status=init"

begin
  brick_pipeline = GoodData::Bricks::Pipeline.send("#{brick_type}_pipeline")
  params = ENV.select { |k,| k.to_s.match(/^#{BRICK_PARAM_PREFIX}.*/) }.map { |k, v| [k.slice(BRICK_PARAM_PREFIX.length..-1), v] }.to_h
  commit_hash = ENV['GOODDATA_RUBY_COMMIT'] || ''
  params['gooddata_ruby_commit'] = commit_hash
  params['log_directory'] = ENV['LOG_DIRECTORY'] || '/tmp/'
  log.info "action=#{brick_type}_execution status=start commit_hash=#{commit_hash}"
  @brick_result = brick_pipeline.call(params)
  log.info "action=#{brick_type}_execution status=finished"
rescue NoMethodError => e
  log.info "action=#{brick_type}_execution status=error Invalid brick type '#{brick_type}', #{e.message}"
  raise e
rescue => e
  log.info "action=#{brick_type}_execution status=error #{e.message}"
  raise e
end
