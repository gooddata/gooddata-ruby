require 'benchmark'

module GoodData::Bricks

  class BenchMiddleware < GoodData::Bricks::Middleware

    def call(params)
      puts "Starting timer"
      result = nil
      report = Benchmark.measure { result = @app.call(params) }
      puts "Stopping timer"
      pp report
      result
    end

  end
end