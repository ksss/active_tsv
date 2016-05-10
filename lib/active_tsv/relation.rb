# frozen_string_literal: true

module ActiveTsv
  class Relation
    include Enumerable

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

    def exists?
      !first.nil?
    end

    def first
      if @order_values.empty?
        if @where_values.empty?
          first_value = @model.open { |csv| csv.gets; csv.gets }
          @model.new(first_value)
        else
          each_yield.first
        end
      else
        to_a.first
      end
    end

    BUF_SIZE = 1024

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
          each_yield.take(n)
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
      @order_values += columns
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
      ret = each_yield.to_a
      if @order_values.empty?
        ret
      else
        ret.sort_by do |i|
          @order_values.map { |m| i[m] }.join('-')
        end
      end
    end

    def inspect
      a = to_a.take(11).map(&:inspect)
      a[10] = '...' if a.length == 11

      "#<#{self.class.name} [#{a.join(', ')}]>"
    end

    private

    def each_yield
      return to_enum(:each_yield) unless block_given?

      key_to_value_index = @model.keys.each_with_index.to_h
      @model.open do |csv|
        csv.gets
        csv.each do |value|
          yield @model.new(value) if @where_values.all? { |cond|
            cond.values.all? do |k, v|
              value[key_to_value_index[k]].__send__(cond.method_name, v.to_s)
            end
          }
        end
      end
    end
  end
end
