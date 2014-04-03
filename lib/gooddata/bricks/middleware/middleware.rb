# encoding: UTF-8
require 'pathname'

base = Pathname(__FILE__).dirname.expand_path
Dir.glob("#{base}/*_middleware.rb").each do |file|
  require file
end
