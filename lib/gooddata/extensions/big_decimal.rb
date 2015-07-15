# encoding: UTF-8

require 'bigdecimal'

class BigDecimal
  def duplicable?
    true
  end

  def pretty_print(p)
    p.text to_s
  end
end
