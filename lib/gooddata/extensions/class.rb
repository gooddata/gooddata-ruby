class Class
  def short_name
    name.split('::').last
  end

  def descendants
    ObjectSpace.each_object(Class).select do |klass|
      klass < self
    end
  end
end
