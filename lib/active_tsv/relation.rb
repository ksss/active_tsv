# frozen_string_literal: true

module ActiveTsv
  class Relation
    def initialize(table, conditions)
      @table = table
      @conditions = conditions
    end

    def where(conditions)
      self.class.new(@table, @conditions.merge(conditions))
    end

    def exist?
      !first.nil?
    end

    def first
      @table.find do |i|
        @conditions.all? do |k, v|
          i[k] == v.to_s
        end
      end
    end

    def last
      to_a.last
    end

    def to_a
      @table.select do |i|
        @conditions.all? do |k, v|
          i[k] == v.to_s
        end
      end
    end
  end
end
