# frozen_string_literal: true

module ActiveTsv
  class Ordering < Struct.new(:column)
    VALID_DIRECTIONS = [:asc, :desc, :ASC, :DESC, "asc", "desc", "ASC", "DESC"]

    class Ascending < Ordering
      def to_i
        1
      end

      def ascending?
        true
      end

      def descending?
        false
      end
    end

    class Descending < Ordering
      def to_i
        -1
      end

      def ascending?
        false
      end

      def descending?
        true
      end
    end
  end
end
