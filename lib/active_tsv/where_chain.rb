module ActiveTsv
  class WhereChain
    def initialize(relation)
      @relation = relation
    end

    def not(condition)
      Relation.new(@table, @conditions << Condition.new(:!=, condition))
    end
  end
end
