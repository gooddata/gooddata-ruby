module GDC
    module Resources
        class Obj < GDC::Resources::SingularBase 
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/md/:project_hash"
            
            
            def structure_root
              attributes.keys[0]
            end
        end
    end
end