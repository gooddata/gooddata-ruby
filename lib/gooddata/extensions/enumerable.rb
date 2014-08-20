# encoding: UTF-8

module Enumerable
  def mapcat(initial = [], &block)
    reduce(initial) do |a, e|
      block.call(e).each do |x|
        a << x
      end
      a
    end
  end

  def pmapcat(initial = [], &block)
    intermediate = pmap(&block)
    intermediate.reduce(initial) do |a, e|
      e.each do |x|
        a << x
      end
      a
    end
  end
end
