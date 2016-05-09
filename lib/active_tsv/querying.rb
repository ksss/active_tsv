module ActiveTsv
  module Querying
    %i(first last take where count order).each do |m|
      module_eval <<-DEFINE_METHOD, __FILE__, __LINE__
        def #{m}(*args, &block)
          all.#{m}(*args, &block)
        end
      DEFINE_METHOD
    end
  end
end
