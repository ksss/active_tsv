# frozen_string_literal: true

module ActiveTsv
  class Relation
    include Enumerable

    BUF_SIZE = 1024

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

    def find(*ids)
      case ids.length
      when 0
        raise ActiveTsv::RecordNotFound, "Couldn't find #{@model} without an ID"
      when 1
        id = ids.first
        record = where(@model.primary_key => id).first
        unless record
          raise ActiveTsv::RecordNotFound, "Couldn't find #{@model} with '#{@model.primary_key}'=#{id}"
        end
        record
      else
        records = where(@model.primary_key => ids).to_a
        unless ids.length == records.length
          raise ActiveTsv::RecordNotFound, "Couldn't find all #{@model} with '#{@model.primary_key}': (#{ids.join(', ')}) (found #{records.length} results, but was looking for #{ids.length})"
        end
        records
      end
    end

    def where(where_value = nil)
      if where_value
        dup.tap do |r|
          values = where_value.map { |k, v| [k.to_sym, v] }.to_h
          r.where_values << Condition::Equal.new(values)
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
        last_value = File.open(@model.table_path, "r:#{@model.encoding}:UTF-8") do |f|
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
          to_value_a.take(n).map { |i| @model.new(i) }
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

    def maximum(column)
      index = @model.keys.each_with_index.to_h[column]
      max = each_value.max_by { |i| i[index] }
      return nil unless max
      max[index]
    end

    def minimum(column)
      index = @model.keys.each_with_index.to_h[column]
      min = each_value.min_by { |i| i[index] }
      return nil unless min
      min[index]
    end

    private

    def to_value_a
      ret = each_value.to_a
      if @order_values.empty?.!
        key_to_value_index = @model.keys.each_with_index.to_h
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
              case cond
              when Condition::Equal
                case v
                when Array
                  v.any? { |vv| value[key_to_value_index[k]] == vv.to_s }
                else
                  value[key_to_value_index[k]] == v.to_s
                end
              when Condition::NotEqual
                case v
                when Array
                  !v.any? { |vv| value[key_to_value_index[k]] == vv.to_s }
                else
                  !(value[key_to_value_index[k]] == v.to_s)
                end
              else
                raise Condition::NotSupportError, "Dose not support condition #{cond}"
              end
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
          Ordering::Ascending.new(column)
        when Hash
          column.map do |col, direction|
            unless Ordering::VALID_DIRECTIONS.include?(direction)
              raise ArgumentError, %(Direction "#{direction}" is invalid. Valid directions are: #{Ordering::VALID_DIRECTIONS})
            end
            case direction.downcase.to_sym
            when :asc
              Ordering::Ascending.new(col)
            when :desc
              Ordering::Descending.new(col)
            end
          end
        end
      }.flatten
    end
  end
end
