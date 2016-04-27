# frozen_string_literal: true

require 'csv'
require "active_tsv/relation"

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

      def where(conditions)
        Relation.new(self, conditions)
      end
    end

    def initialize(values = {})
      @attrs = case values
      when Hash
        values
      else
        raise ArgumentError, "#{values.class} is not supported value"
      end

      self.class.keys.each { |k| __send__ "#{k}=", @attrs[k] }
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
