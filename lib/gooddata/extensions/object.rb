# encoding: UTF-8

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def duplicable?
    true
  end
end
