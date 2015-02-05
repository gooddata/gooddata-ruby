# encoding: UTF-8

module GoodData
  module Command
    # Also known as ADS and DSS
    class DataWarehouse
      class << self
        # Create new project based on options supplied
        def create(options = { client: GoodData.connection })
          title = options[:title]
          description = options[:summary] || options[:description]
          token = options[:token] || options[:auth_token]
          client = options[:client]
          GoodData::DataWarehouse.create(:title => title,
                                         :description => description,
                                         :auth_token => token,
                                         :client => client)
        end
      end
    end
  end
end
