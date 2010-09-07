module GDC
  module Resources
    class LoginSession
      
      puts "inside LoginSession"
      
      def initialize(data)
          @attributes = data
          @cookies = {}
      end
    
      def get_profile_uri
          @attributes['userLogin']['profile']
      end
    
      def get_profile_id
          get_profile_uri.split('/').last
      end
    
      def get_state_uri
          @attributes['userLogin']['state']
      end
    
      def get_state_id
          get_state_uri.split('/').last
      end
    
      def parse_cookies(response)
        response.each_header do |k, v|
          if k === 'set-cookie'
            v = v.split(",")
            v.each do |v|
              v=v.split(';')[0].split('=')
              if !v[1].nil?
                @cookies[v[0].strip] = v[1].strip
              end
            end
          end
        end
      end
    
      def add_cookies(response, headers)
        parse_cookies(response)
        headers['Cookie'] = ""
        @cookies.each_pair {|k, v| headers['Cookie'] += "#{k}=#{CGI.escape(v)}; "}
      end
    
      def add_csrf_protection(key, headers)
        headers['X-GDC-AUTH'] = CGI.escape(@cookies[key.to_s])
      end
    
      def get_token(options = {})
        Token.refresh(options)
      end
    end
  end
end