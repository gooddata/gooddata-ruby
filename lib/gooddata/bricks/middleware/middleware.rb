Dir[File.dirname(__FILE__) + '/middleware/**/*_middleware.rb'].each do |file|
  require file
end