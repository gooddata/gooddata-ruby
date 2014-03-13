require File.join(File.dirname(__FILE__), 'shared')

Dir[File.dirname(__FILE__) + '/commands/**/*_cmd.rb'].each do |file|
  require file
end

require File.join(File.dirname(__FILE__), 'hooks')