# encoding: UTF-8

class Symbol
  # Symbols are not duplicable:
  #
  #   :my_symbol.duplicable? # => false
  #   :my_symbol.dup         # => TypeError: can't dup Symbol
  def duplicable?
    false
  end
end
