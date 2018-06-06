# encoding: utf-8

# Required gems
require 'bundler/setup'
require 'gooddata'

# Hack the loading path - https://jira.intgdc.com/browse/MSF-11678
$:.unshift(File.dirname(__FILE__))

# Load the brick
require 'hello_world_brick'

include GoodData::Bricks

stack = [
  DecodeParamsMiddleware,
  LoggerMiddleware,
  BenchMiddleware,
  HelloWorldBrick
]
p = GoodData::Bricks::Pipeline.prepare(stack)
p.call($SCRIPT_PARAMS.to_hash)
