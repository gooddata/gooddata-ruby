module GoodData::Command
  class Scaffold
    class << self

      def brick(name)
        
        require 'erubis'
        require 'fileutils'
        
        templates_path = Pathname(__FILE__) + "../../../templates"
        
        FileUtils.mkdir(name)
        FileUtils.cd(name) do
          input = File.read(templates_path + 'bricks/brick.rb.erb')
          eruby = Erubis::Eruby.new(input)
          File.open("brick.rb", 'w') do |f|
            f.write(eruby.result())
          end
          
          input = File.read(templates_path + 'bricks/main.rb.erb')
          eruby = Erubis::Eruby.new(input)
          File.open("main.rb", 'w') do |f|
            f.write(eruby.result())
          end
        end
      end

    end
  end
end