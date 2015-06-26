# encoding: UTF-8

class FalseClass
  # +false+ is not duplicable:
  #
  #   false.duplicable? # => false
  #   false.dup         # => TypeError: can't dup FalseClass
  def duplicable?
    false
  end
end
