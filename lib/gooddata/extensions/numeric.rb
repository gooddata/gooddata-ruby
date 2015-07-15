# encoding: UTF-8

class Numeric
  # Numbers are not duplicable:
  #
  #  3.duplicable? # => false
  #  3.dup         # => TypeError: can't dup Fixnum
  def duplicable?
    false
  end
end
