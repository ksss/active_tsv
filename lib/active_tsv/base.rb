# frozen_string_literal: true

module ActiveTsv
  # @example
  #   class User < ActiveTsv::Base
  #     self.table_path = "table/product_masters.tsv"
  #   end
  class Base
    SEPARATER = "\t"
    class << self
      include Enumerable
      attr_reader :table_path

      def table_path=(path)
        reload(path)
      end

      def reload(path)
        old_table_path = table_path
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
      rescue
        reload(old_table_path)
        raise
      end

      def each
        open do |f|
          f.gets
          f.each do |i|
            yield new(keys.zip(i).to_h)
          end
        end
      end

      def all
        to_a
      end

      def last
        last_values = open { |f| f.to_a.last }
        new(keys.zip(last_values).to_h)
      end

      def open(&block)
        CSV.open(table_path, col_sep: self::SEPARATER, &block)
      end

      def keys
        @keys ||= open { |f| f.gets }.map(&:to_sym)
      end

      def where(condition = nil)
        if condition
          Relation.new(self, [Condition.new(:==, condition)])
        else
          WhereChain.new(self, [])
        end
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
      h = {}
      self.class.keys.map { |k| h[k] = __send__ k }
      h
    end
  end
end
