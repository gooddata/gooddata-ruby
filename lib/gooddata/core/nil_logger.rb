# encoding: UTF-8

module GoodData
  # Dummy implementation of logger
  class NilLogger
    def debug(*_args)
    end

    alias_method :info, :debug
    alias_method :warn, :debug
    alias_method :error, :debug
  end
end
