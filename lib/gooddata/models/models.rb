# encoding: UTF-8

require 'pathname'

require_relative 'attributes/attributes'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require_relative file
end