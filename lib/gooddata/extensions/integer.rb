module IntegerExtensions
  refine Integer do
    def to_b
      self == 1
    end
  end
end
