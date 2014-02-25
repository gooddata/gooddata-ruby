module GoodData::Command
  class Scaffold
    class << self

      def project(name)
        require 'erubis'
        require 'fileutils'

        templates_path = Pathname(__FILE__) + "../../../templates"

        FileUtils.mkdir(name)
        FileUtils.cd(name) do

          FileUtils.mkdir("model")
          FileUtils.cd("model") do
            input = File.read(templates_path + 'project/model/model.rb.erb')
            eruby = Erubis::Eruby.new(input)
            File.open("model.rb", 'w') do |f|
              f.write(eruby.result(:name => name))
            end
          end

          FileUtils.mkdir("data")
          FileUtils.cd("data") do
            FileUtils.cp(Dir.glob(templates_path + 'project/data/*.csv'), ".")
          end

          input = File.read(templates_path + 'project/Goodfile.erb')
          eruby = Erubis::Eruby.new(input)
          File.open("Goodfile", 'w') do |f|
            f.write(eruby.result())
          end
        end
      end

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