# frozen_string_literal: true

module ActiveTsv
  class Relation
    include Enumerable

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
      keys = @table.keys
      key_to_value_index = keys.each_with_index.map { |k, index| [k, index] }.to_h
      value = @table.open { |csv|
        csv.gets
        csv.find do |value|
          @conditions.all? do |cond|
            cond.values.all? do |k, v|
              value[key_to_value_index[k]].__send__(cond.method_name, v.to_s)
            end
          end
        end
      }
      if value
        @table.new(@table.keys.zip(value).to_h)
      else
        nil
      end
    end

    def last
      to_a.last
    end

    def each
      return to_enum(:each) unless block_given?

      keys = @table.keys
      key_to_value_index = keys.each_with_index.map { |k, index| [k, index] }.to_h
      values = @table.open { |csv|
        csv.gets
        csv.select do |value|
          @conditions.all? do |cond|
            cond.values.all? do |k, v|
              value[key_to_value_index[k]].__send__(cond.method_name, v.to_s)
            end
          end
        end
      }
      values.each do |value|
        yield @table.new(@table.keys.zip(value).to_h)
      end
    end
  end
end
