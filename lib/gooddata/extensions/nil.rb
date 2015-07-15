# encoding: UTF-8

class NilClass
  # +nil+ is not duplicable:
  #
  #   nil.duplicable? # => false
  #   nil.dup         # => TypeError: can't dup NilClass
  def duplicable?
    false
  end
end
