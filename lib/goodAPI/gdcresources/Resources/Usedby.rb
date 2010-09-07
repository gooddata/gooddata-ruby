module GDC
    module Resources
        class Usedby < GDC::Resources::Edges
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/md/:project_hash"
            structure_root :usedby
            ignore_nodes []
        end
    end
end