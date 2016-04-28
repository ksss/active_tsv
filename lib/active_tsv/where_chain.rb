module ActiveTsv
  class WhereChain
    def initialize(table, conditions)
      @table = table
      @conditions = conditions
    end

    def not(condition)
      Relation.new(@table, @conditions << Condition.new(:!=, condition))
    end
  end
end
