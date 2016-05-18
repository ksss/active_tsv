# frozen_string_literal: true

module ActiveTsv
  class Relation
    include Enumerable

    BUF_SIZE = 1024
    VALID_DIRECTIONS = [:asc, :desc, :ASC, :DESC, "asc", "desc", "ASC", "DESC"]

    attr_reader :model
    attr_accessor :where_values
    attr_accessor :order_values
    attr_accessor :group_values

    def initialize(model)
      @model = model
      @where_values = []
      @order_values = []
      @group_values = []
    end

    def initialize_copy(copy)
      copy.where_values = where_values.dup
      copy.order_values = order_values.dup
      copy.group_values = group_values.dup
    end

    def ==(other)
      where_values == other.where_values &&
        order_values == other.order_values &&
        group_values == other.group_values
    end

    def where(where_value = nil)
      if where_value
        dup.tap do |r|
          r.where_values << Condition.new(:==, where_value)
        end
      else
        WhereChain.new(dup)
      end
    end

    def pluck(*fields)
      key_to_value_index = @model.keys.each_with_index.to_h
      if fields.empty?
        to_value_a
      elsif fields.one?
        field = fields.first
        to_value_a.map { |v| v[key_to_value_index[field]] }
      else
        to_value_a.map { |v| fields.map { |field| v[key_to_value_index[field]] } }
      end
    end

    def exists?
      !first.nil?
    end

    def first
      if @order_values.empty?
        each_model.first
      else
        to_a.first
      end
    end

    def last
      if @where_values.empty? && @order_values.empty?
        last_value = File.open(@model.table_path) do |f|
          f.seek(0, IO::SEEK_END)
          buf_size = [f.size, self.class::BUF_SIZE].min
          while true
            f.seek(-buf_size, IO::SEEK_CUR)
            buf = f.read(buf_size)
            if index = buf.rindex($INPUT_RECORD_SEPARATOR, -2)
              f.seek(-buf_size + index + 1, IO::SEEK_CUR)
              break f.read.chomp
            else
              f.seek(-buf_size, IO::SEEK_CUR)
            end
          end
        end
        @model.new(CSV.new(last_value, col_sep: @model::SEPARATER).shift)
      else
        to_a.last
      end
    end

    def take(n = nil)
      if n
        if @order_values.empty?
          each_model.take(n)
        else
          to_a.take(n)
        end
      else
        first
      end
    end

    def count
      if @group_values.empty?
        super
      else
        h = if @group_values.one?
          group_by { |i| i[@group_values.first] }
        else
          group_by { |i| @group_values.map { |c| i[c] } }
        end
        h.each do |k, v|
          h[k] = v.count
        end
        h
      end
    end

    def order(*columns)
      @order_values += order_conditions(columns)
      @order_values.uniq!
      self
    end

    def group(*columns)
      @group_values += columns
      @group_values.uniq!
      self
    end

    def each(*args, &block)
      to_a.each(*args, &block)
    end

    def to_a
      to_value_a.map { |v| @model.new(v) }
    end

    def inspect
      a = to_a.take(11).map(&:inspect)
      a[10] = '...' if a.length == 11

      "#<#{self.class.name} [#{a.join(', ')}]>"
    end

    private

    def to_value_a
      ret = each_value.to_a
      key_to_value_index = @model.keys.each_with_index.to_h
      if @order_values.empty?.!
        if @order_values.one?
          order_condition = @order_values.first
          index = key_to_value_index[order_condition.column]
          ret.sort_by! { |i| i[index] }
          if order_condition.descending?
            ret.reverse!
          end
        else
          ret.sort! do |a, b|
            @order_values.each.with_index(1) do |order_condition, index|
              comp = a[key_to_value_index[order_condition.column]] <=> b[key_to_value_index[order_condition.column]]
              break 0 if comp == 0 && index == @order_values.length
              break comp * order_condition.to_i if comp != 0
            end
          end
        end
      end
      ret
    end

    def each_value
      return to_enum(__method__) unless block_given?

      key_to_value_index = @model.keys.each_with_index.to_h
      @model.open do |csv|
        csv.gets
        csv.each do |value|
          yield value if @where_values.all? { |cond|
            cond.values.all? do |k, v|
              value[key_to_value_index[k]].__send__(cond.method_name, v.to_s)
            end
          }
        end
      end
    end

    def each_model
      return to_enum(__method__) unless block_given?

      each_value { |v| yield @model.new(v) }
    end

    def order_conditions(columns)
      columns.map { |column|
        case column
        when Symbol
          Ascending.new(column)
        when Hash
          column.map do |col, direction|
            unless VALID_DIRECTIONS.include?(direction)
              raise ArgumentError, %(Direction "#{direction}" is invalid. Valid directions are: #{VALID_DIRECTIONS})
            end
            case direction.downcase.to_sym
            when :asc
              Ascending.new(col)
            when :desc
              Descending.new(col)
            end
          end
        end
      }.flatten
    end
  end
end
