require 'sqlite3' unless RUBY_PLATFORM == 'java'

module GoodData
  class Datawarehouse
    #  existence of Datawarehouse and InMemoryAds implementations is mutually exclusive
    #  this is to make type checks pass, see InMemoryAds#class
  end
end

module Support
  class InMemoryAds
    def initialize
      db = SQLite3::Database.new(':memory:')
      db.results_as_hash = true
      @db = db
    end

    def data
      {
        'connectionUrl' => 'this_should_never_be_used',
        :mocked? => true,
        :schema => schemas
      }
    end

    def schemas
      'irrelevant/schema/uri'
    end

    def obj_id
      'irrelevant_object_id'
    end

    def execute_select(*args, &block)
      execute_with_headers(*args, &block)
    end

    def execute(*args, &block)
      execute_with_headers(*args, &block)
    end

    def execute_with_headers(*args)
      res = @db.execute(*args)
      res.map do |row|
        # sqlite3 returns hash with both column names and numbers, we want only names
        res = GoodData::Helpers.symbolize_keys(row.reject { |k, _| k.is_a? Integer })
        yield res if block_given?
        res
      end
    end

    def class
      # so typechecking before running LCM actions works
      GoodData::Datawarehouse
    end
  end
end
