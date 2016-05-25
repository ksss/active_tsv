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

    def has_one(name)
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          #{name.to_s.singularize.classify}.where(
            "#{self.name.downcase}_id" => self[self.class.primary_key]
          ).first
        end
      CODE
    end

    def belongs_to(name)
      define_method(name) do
        klass = name.to_s.classify.constantize
        klass.where(klass.primary_key => self["#{name}_id"]).first
      end
    end
  end
end
