# frozen_string_literal: true

module ActiveTsv
  class Relation
    def initialize(table, conditions)
      @table = table
      @conditions = conditions
    end

    def where(condition = nil)
      if condition
        self.class.new(@table, @conditions << Condition.new(:==, condition))
      else
        WhereChain.new(@table, @conditions)
      end
    end

    def exist?
      !first.nil?
    end

    def first
      @table.find do |i|
        @conditions.all? do |cond|
          cond.values.all? do |k, v|
            i[k].__send__(cond.method_name, v.to_s)
          end
        end
      end
    end

    def last
      to_a.last
    end

    def to_a
      @table.select do |i|
        @conditions.all? do |cond|
          cond.values.all? do |k, v|
            i[k].__send__(cond.method_name, v.to_s)
          end
        end
      end
    end
  end
end
