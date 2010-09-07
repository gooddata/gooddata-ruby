module GDC
    module Resources
        class Query < GDC::Resources::SingularBase 
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/md/:project_hash/"
            class << self
                # def get_attributes(arguments)
                #     self.find(:attributes, arguments)
                # end
            end
        end
    end
end