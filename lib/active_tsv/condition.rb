module ActiveTsv
  class Condition < Struct.new(:values)
    NotSupportError = Class.new(StandardError)

    class Equal < Condition
    end

    class NotEqual < Condition
    end
  end
end
