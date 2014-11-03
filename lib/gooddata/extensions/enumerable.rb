# encoding: UTF-8

module Enumerable
  def mapcat(initial = [], &block)
    each_with_object(initial) do |a, e|
      block.call(e).each do |x|
        a << x
      end
      a
    end
  end

  def pmapcat(initial = [], &block)
    intermediate = pmap(&block)
    intermediate.each_with_object(initial) do |a, e|
      e.each do |x|
        a << x
      end
      a
    end
  end

  def pselect(&block)
    intermediate = pmap(&block)
    zip(intermediate).select { |x| x[1] }.map(&:first)
  end
end
