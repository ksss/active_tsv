# frozen_string_literal: true

module ActiveTsv
  # @example
  #   class User < ActiveTsv::Base
  #     self.table_path = "table/product_masters.tsv"
  #   end
  class Base
    SEPARATER = "\t"
    DEFAULT_PRIMARY_KEY = "id"

    class << self
      include Querying

      attr_reader :table_path
      attr_writer :primary_key
      attr_reader :encoding

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
        @encoding ||= File.open(path) { |f| NKF.guess(f.gets) }
        keys.each do |k|
          define_method(k) { @attrs[k] }
          define_method("#{k}=") { |v| @attrs[k] = v }
        end
      end

      def all
        Relation.new(self)
      end

      def scope(name, proc)
        define_singleton_method(name, &proc)
      end

      def open(&block)
        CSV.open(table_path, "r:#{@encoding}:UTF-8", col_sep: self::SEPARATER, &block)
      end

      def keys
        @keys ||= open { |csv| csv.gets }.map(&:to_sym)
      end

      def keys=(headers)
        @keys = headers.map(&:to_sym)
      end

      def primary_key
        @primary_key ||= DEFAULT_PRIMARY_KEY
      end

      def encoding=(enc)
        case enc
        when String
          @encoding = Encoding.find(enc)
        when Encoding
          @encoding = enc
        else
          raise TypeError, "#{enc.class} dose not support"
        end
      end
    end

    def initialize(attrs = {})
      case attrs
      when Hash
        @attrs = attrs
      when Array
        @attrs = self.class.keys.zip(attrs).to_h
      else
        raise ArgumentError, "#{attrs.class} is not supported value"
      end
    end

    def inspect
      "#<#{self.class} #{@attrs.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')}>"
    end

    def [](key)
      @attrs[key.to_sym]
    end

    def []=(key, value)
      @attrs[key.to_sym] = value
    end

    def attributes
      @attrs.dup
    end

    def ==(other)
      super || other.instance_of?(self.class) && attributes == other.attributes
    end
    alias eql? ==
  end
end
