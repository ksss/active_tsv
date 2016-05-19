module ActiveTsv
  module Querying
    METHODS = %i(find first last take where count order group pluck minimum maximum)
    METHODS.each do |m|
      module_eval <<-DEFINE_METHOD, __FILE__, __LINE__ + 1
        def #{m}(*args, &block)
          all.#{m}(*args, &block)
        end
      DEFINE_METHOD
    end
  end
end
