# encoding: UTF-8

base = Pathname(__FILE__).dirname.expand_path
Dir.glob(base + '*.rb').each do |file|
  require file
end

# Require all middleware
require File.join(File.dirname(__FILE__), 'middleware/middleware')