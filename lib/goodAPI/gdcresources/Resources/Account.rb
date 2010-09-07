module GDC
    module Resources
        class Account < GDC::Resources::SingularBase
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/account"
            self.element_name = "profile"
            
            structure_root :accountSetting
            
            def get_projects(options = {})
              return connection.get(links.projects, options[:headers])
              # By activating this and slightly changing th upper line, list of resources would be returned, which is cool, but is extremely awkward to serialize again, because we are discarding aprt of the information here
              # GDC::Resources::Project.instantiate_collection(response["projects"])
            end
            
        end
    end
end
