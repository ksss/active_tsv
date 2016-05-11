module ActiveTsv
  Ordering = Struct.new(:column)

  class Ascending < Ordering
    def to_i
      1
    end
  end

  class Descending < Ordering
    def to_i
      -1
    end
  end
end
