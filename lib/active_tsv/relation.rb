# frozen_string_literal: true

module ActiveTsv
  class Relation
    include Enumerable

    attr_reader :model
    attr_reader :where_values
    def initialize(model, where_values, order_values = [])
      @model = model
      @where_values = where_values
      @order_values = order_values
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

    BUF_SIZE = 1024

    def last
      if @where_values.empty?
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
        @model.new(@model.keys.zip(CSV.new(last_value, col_sep: @model::SEPARATER).shift).to_h)
      else
        to_a.last
      end
    end

    def order(*columns)
      @order_values += columns
      self
    end

    def each(*args, &block)
      to_a.each(*args, &block)
    end

    def to_a
      ret = []
      keys = @model.keys
      key_to_value_index = keys.each_with_index.map { |k, index| [k, index] }.to_h
      @model.open do |csv|
        csv.gets
        csv.each do |value|
          ret << @model.new(keys.zip(value).to_h) if @where_values.all? { |cond|
            cond.values.all? do |k, v|
              value[key_to_value_index[k]].__send__(cond.method_name, v.to_s)
            end
          }
        end
      end
      if @order_values.empty?
        ret
      else
        ret.sort_by do |i|
          @order_values.map { |m| i[m] }.join('-')
        end
      end
    end
  end
end
