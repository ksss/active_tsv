module ActiveTsv
  module Reflection
    def has_many(name, through: nil)
      if through
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}
            #{name.to_s.classify}.where(
              #{name.to_s.classify}.primary_key => #{through}.pluck("#{name.to_s.singularize.underscore}_id")
            )
          end
        CODE
      else
        class_eval <<-CODE, __FILE__, __LINE__ + 1
          def #{name}
            #{name.to_s.singularize.classify}.where(
              "#{self.name.underscore}_id" => self[self.class.primary_key]
            )
          end
        CODE
      end
    end

    def has_one(name)
      class_eval <<-CODE, __FILE__, __LINE__ + 1
        def #{name}
          #{name.to_s.singularize.classify}.where(
            "#{self.name.underscore}_id" => self[self.class.primary_key]
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
