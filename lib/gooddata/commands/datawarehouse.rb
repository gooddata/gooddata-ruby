# encoding: UTF-8

module GoodData
  module Command
    # Also known as ADS and DSS
    class DataWarehouse
      class << self
        # Create new project based on options supplied
        def create(options = { client: GoodData.connection })
          description = options[:summary] || options[:description]
          GoodData::DataWarehouse.create(options.merge(:description => description))
        end
      end
    end
  end
end
