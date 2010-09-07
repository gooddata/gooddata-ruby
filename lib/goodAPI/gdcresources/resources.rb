$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

# gem 'activeresource', '>= 2.3.5'
require 'active_resource'

module GDC
    module Resources
        SERVER_URI = "example.com"
    end
end


require 'Resources/Base'
require 'Resources/PluralBase'
require 'Resources/SingularBase'
require 'Resources/Account'
require 'Resources/Token'
require 'Resources/Obj'
require 'Resources/Query'
require 'Resources/Project'
require 'Resources/Login'
require 'Resources/Session'
require 'Resources/Meta'
require 'Resources/Links'
require 'Resources/Edges'
require 'Resources/Usedby'
require 'Resources/Using'
require 'Resources/Relation'
require 'Resources/Tag'

GDC::Resources::Base.logger = Logger.new(STDOUT)