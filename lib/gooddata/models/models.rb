# encoding: UTF-8
require_relative 'attributes/attributes'
require 'pathname'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require_relative file
end