module GDC
    module Resources
        class Project < GDC::Resources::PluralBase
            
            structure_root :project
            
            self.site = "#{GDC::Resources::SERVER_URI}/gdc"
            
            def get_roles(options)
              response = connection.get(links.projects, options[:headers] || {})
            end
            
            def get_users
              response = connection.get(links.users, options[:headers] || {})
            end
            
            def get_permissions(user, options)
              path = [links.users, user.id, 'permissions'].join('/')
              response = connection.get(path, options[:headers] || {})
            end
        end
    end
end