module GDC
    module Resources
        class Relation
            
            attr_reader :attributes
            
            def initialize(attributes)
              @attributes = attributes
            end
            
            def to
              attributes["to"]
            end
            
            def to=(an_object)
              attributes["to"] = an_object
            end
            
            def from
              attributes["from"]
            end
            
            def from=(an_object)
              attributes["from"] = an_object
            end
        end
    end
end