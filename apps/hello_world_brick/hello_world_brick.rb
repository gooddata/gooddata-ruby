# encoding: utf-8

module GoodData::Bricks
  class HelloWorldBrick < GoodData::Bricks::Brick
    def version
      '0.0.1'
    end

    def call(params)
      puts "GoodData::VERSION = #{GoodData::VERSION}"

      print_reverted = params['print_reverted']
      if print_reverted
        print_reverted.split(',').each do |key|
          stripped_key = key.strip
          value = params[stripped_key] || params[stripped_key.to_sym]
          if value
            puts "Reverted '#{key}' = '#{value.reverse}'"
          end
        end
      end

      puts JSON.pretty_generate(params)
    end
  end
end
