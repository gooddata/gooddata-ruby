# encoding: UTF-8

require 'bigdecimal'

class BigDecimal
  def pretty_print(p)
    p.text to_s
  end
end
