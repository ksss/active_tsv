module ActiveTsv
  class Condition < Struct.new(:values)
    class Equal < Condition
    end

    class NotEqual < Condition
    end
  end
end
