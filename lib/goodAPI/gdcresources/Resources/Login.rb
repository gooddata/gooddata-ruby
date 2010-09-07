module GDC
    module Resources
        class Login < GDC::Resources::SingularBase
            self.site = "#{GDC::Resources::SERVER_URI}/gdc/account"
            class << self
                
                def login(login, password, options = {})
                    # puts ">>> logging in as #{login}"
                    
                    response = connection.post(collection_path, "{\"postUserLogin\":{\"login\":\"#{login}\",\"password\":\"#{password}\",\"remember\":\"0\"}}", options[:headers])
                    session = LoginSession.new(format.decode(response.body))
                    
                    session.add_cookies(response, options[:headers])
                    session.add_csrf_protection(:GDCAuthSST, options[:headers])
                    response = session.get_token(options)
                    session.add_cookies(response, options[:headers])
                    session.add_csrf_protection(:GDCAuthTT, options[:headers])
                    
                    
                    if block_given?
                      yield session
                      logout(session.get_state_id, options)
                    else
                      session
                    end
                end
                
                def logout(state_id, options = {})
                  connection.delete("#{collection_path}/#{state_id}", options[:headers])
                end
                
            end
        end
    end
end