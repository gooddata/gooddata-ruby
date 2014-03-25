# encoding: UTF-8

module GoodData::Bricks
  module Utils
    def returning(value, &block)
      fail 'Block was not provided' if block.nil?
      return_val = value
      block.call(value)
      return_val
    end
  end
end