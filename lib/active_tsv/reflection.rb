module ActiveTsv
  module Reflection
    def has_many(name)
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          #{name.to_s.singularize.classify}.where(
            "#{self.name.downcase}_id" => self[self.class.primary_key]
          )
        end
      CODE
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
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          #{name.to_s.classify}.where(self.class.primary_key => self["#{name}_id"]).first
        end
      CODE
    end
  end
end
