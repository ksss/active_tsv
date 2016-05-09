# frozen_string_literal: true

require 'active_tsv/querying'

module ActiveTsv
  # @example
  #   class User < ActiveTsv::Base
  #     self.table_path = "table/product_masters.tsv"
  #   end
  class Base
    SEPARATER = "\t"

    class << self
      include Querying

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

      def open(&block)
        CSV.open(table_path, col_sep: self::SEPARATER, &block)
      end

      def keys
        @keys ||= open { |csv| csv.gets }.map(&:to_sym)
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

    def ==(other)
      super || other.instance_of?(self.class) && to_h == other.to_h
    end
    alias eql? ==
  end
end
