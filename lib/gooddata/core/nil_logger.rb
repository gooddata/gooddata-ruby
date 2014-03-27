# encoding: UTF-8

module GoodData
  # Dummy implementation of logger
  class NilLogger
    def debug(*args)
      ;
    end

    alias :info :debug
    alias :warn :debug
    alias :error :debug
  end
end