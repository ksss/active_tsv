# frozen_string_literal: true

module ActiveTsv
  # @example
  #   class User < ActiveTsv::Base
  #     self.table_path = "table/product_masters.tsv"
  #   end
  class Base
    SEPARATER = "\t"
    BUF_SIZE = 1024

    class << self
      attr_reader :table_path

      def table_path=(path)
        reload(path)
      end

      def reload(path)
        if @keys
          keys.each do |k|
            remove_method(k)
            remove_method("#{k}=")
          end
        end

        @keys = nil
        @table_path = path
        keys.each do |k|
          define_method(k) { @attrs[k] }
          define_method("#{k}=") { |v| @attrs[k] = v }
        end
      end

      def all
        Relation.new(self, [])
      end

      def first
        first_value = open { |csv| csv.gets; csv.gets }
        new(keys.zip(first_value).to_h)
      end

      def last
        last_value = File.open(table_path) do |f|
          f.seek(0, IO::SEEK_END)
          size = f.size
          buf_size = [size, self::BUF_SIZE].min
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
        new(keys.zip(CSV.new(last_value, col_sep: self::SEPARATER).shift).to_h)
      end

      def open(&block)
        CSV.open(table_path, col_sep: self::SEPARATER, &block)
      end

      def keys
        @keys ||= open { |csv| csv.gets }.map(&:to_sym)
      end

      def where(condition = nil)
        all.where(condition)
      end

      def count
        all.count
      end

      def order(*columns)
        all.order(*columns)
      end
    end

    def initialize(attrs = {})
      unless attrs.kind_of?(Hash)
        raise ArgumentError, "#{attrs.class} is not supported value"
      end

      @attrs = attrs
    end

    def inspect
      "#<#{self.class} #{to_h}>"
    end

    def [](key)
      __send__ key
    end

    def []=(key, value)
      __send__ "#{key}=", value
    end

    def to_h
      @attrs.dup
    end
  end
end
