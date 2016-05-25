module ActiveTsv
  module Reflection
    def has_many(name)
      define_method(name) do
        singularized = name.to_s.singularize
        reflection_id = "#{self.class.name.downcase}_id"
        klass = singularized.classify.constantize
        klass.where(reflection_id => self[self.class.primary_key])
      end
    end

    def belongs_to(name)
      define_method(name) do
        klass = name.to_s.classify.constantize
        klass.where(klass.primary_key => self["#{name}_id"]).first
      end
    end
  end
end
