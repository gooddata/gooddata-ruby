class Smelly < String
  @@class_variable = :whatever
  attr_accessor :dummy

  def x(y1,y2); end
  def y(y1,y2); end
  def z(y1,y2); end
  def foo; end
  def foo!; end
  def bar!; end

  def test
    @ivar
  end
end
