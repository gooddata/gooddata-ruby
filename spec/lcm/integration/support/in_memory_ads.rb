if RUBY_PLATFORM == 'java'
  require 'active_record'
  require 'activerecord-jdbcsqlite3-adapter'
else
  require 'sqlite3'
end

module Support
  class InMemoryAds
    def initialize
      if RUBY_PLATFORM == 'java'
        # Use ActiveRecord with JDBC adapter for JRuby
        ActiveRecord::Base.establish_connection(
          adapter: 'sqlite3',
          database: ':memory:'
        )
        @db = ActiveRecord::Base.connection
      else
        # Use sqlite3 gem for MRI
        db = SQLite3::Database.new(':memory:')
        db.results_as_hash = true
        @db = db
      end
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
      if RUBY_PLATFORM == 'java'
        # ActiveRecord JDBC adapter
        result = @db.exec_query(*args)
        # ActiveRecord returns arrays of arrays, convert to hash format
        columns = result.columns if result.respond_to?(:columns)
        result.map do |row|
          if row.is_a?(Array) && columns
            # Convert array to hash
            row_hash = columns.zip(row).to_h
            res = GoodData::Helpers.symbolize_keys(row_hash)
          else
            res = GoodData::Helpers.symbolize_keys(row.is_a?(Hash) ? row : {})
          end
          yield res if block_given?
          res
        end
      else
        res = @db.execute(*args)
        res.map do |row|
          # sqlite3 returns hash with both column names and numbers, we want only names
          res = GoodData::Helpers.symbolize_keys(row.reject { |k, _| k.is_a? Integer })
          yield res if block_given?
          res
        end
      end
    end

    def class
      # so typechecking before running LCM actions works
      GoodData::Datawarehouse
    end
  end
end
