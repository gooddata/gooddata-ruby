module GDC
    module Resources
        class Token < GDC::Resources::SingularBase
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/account"
            
            class << self
                def refresh(options = {})
                    response, body_as_json = connection.get_with_side_effects(collection_path, options[:headers])
                    return response
                end
            end
        end
    end
end