# encoding: UTF-8

require 'pathname'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  blacklist = [
    File.join(base, 'rest_getters.rb'),
    File.join(base, 'rest_resource.rb')
  ]

  require file unless blacklist.include? file
end
require_relative 'rest_getters'
require_relative 'rest_resource'
