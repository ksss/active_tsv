module ActiveTsv
  class WhereChain
    def initialize(relation)
      @relation = relation
    end

    def not(condition)
      @relation.dup.tap do |r|
        r.where_values << Condition.new(:!=, condition)
      end
    end
  end
end
