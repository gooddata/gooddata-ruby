module GDC
    module Resources
        class Using < GDC::Resources::Edges
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/md/:project_hash"
            structure_root :using
            ignore_nodes ["table", "tableDataLoad", "column"]
        end
    end
end