module ActiveTsv
  module Querying
    METHODS = %i(first last take where count order group)
    METHODS.each do |m|
      module_eval <<-DEFINE_METHOD, __FILE__, __LINE__
        def #{m}(*args, &block)
          all.#{m}(*args, &block)
        end
      DEFINE_METHOD
    end
  end
end
