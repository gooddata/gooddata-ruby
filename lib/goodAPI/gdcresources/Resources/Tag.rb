module GDC
    module Resources
        class Tag < GDC::Resources::PluralBase
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/md/:project_hash"
            
            def structure_root
              attributes.keys[0]
            end
        end
    end
end