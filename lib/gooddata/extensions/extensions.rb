# encoding: UTF-8

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require_relative file
end
