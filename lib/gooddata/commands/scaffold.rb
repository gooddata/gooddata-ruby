# encoding: UTF-8

require 'erubis'
require 'fileutils'
require 'pathname'

module GoodData
  module Command
    class Scaffold
      TEMPLATES_PATH = Pathname(__FILE__) + '../../../templates'

      class << self
        # Scaffolds new project
        # TODO: Add option for custom output dir
        def project(name)
          fail ArgumentError, 'No name specified' if name.nil?

          FileUtils.mkdir(name)
          FileUtils.cd(name) do
            FileUtils.mkdir('model')
            FileUtils.cd('model') do
              input = File.read(TEMPLATES_PATH + 'project/model/model.rb.erb')
              eruby = Erubis::Eruby.new(input)
              File.open('model.rb', 'w') do |f|
                f.write(eruby.result(:name => name))
              end
            end

            FileUtils.mkdir('data')
            FileUtils.cd('data') do
              FileUtils.cp(Dir.glob(TEMPLATES_PATH + 'project/data/*.csv'), '.')
            end

            input = File.read(TEMPLATES_PATH + 'project/Goodfile.erb')
            eruby = Erubis::Eruby.new(input)
            File.open('Goodfile', 'w') do |f|
              f.write(eruby.result)
            end
          end
        end

        # Scaffolds new brick
        # TODO: Add option for custom output dir
        def brick(name)
          fail ArgumentError, 'No name specified' if name.nil?

          FileUtils.mkdir(name)
          FileUtils.cd(name) do
            input = File.read(TEMPLATES_PATH + 'bricks/brick.rb.erb')
            eruby = Erubis::Eruby.new(input)
            File.open('brick.rb', 'w') do |f|
              f.write(eruby.result)
            end

            input = File.read(TEMPLATES_PATH + 'bricks/main.rb.erb')
            eruby = Erubis::Eruby.new(input)
            File.open('main.rb', 'w') do |f|
              f.write(eruby.result)
            end
          end
        end
      end
    end
  end
end
