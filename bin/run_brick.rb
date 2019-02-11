#!/usr/bin/env ruby

require_relative '../lib/gooddata'

DEFAULT_BRICK = 'hello_world_brick'
BRICK_PARAM_PREFIX = 'BRICK_PARAM_'
HIDDEN_BRICK_PARAMS_PREFIX = 'HIDDEN_BRICK_PARAM_'

brick_type = !ARGV.empty? ? ARGV[0] : DEFAULT_BRICK

def get_brick_params(prefix)
  ENV.select { |k,| k.to_s.match(/^#{prefix}.*/) }.map { |k, v| [k.slice(prefix.length..-1), v] }.to_h
end

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
brick_pipeline.call(params)
