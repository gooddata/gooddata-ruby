module GDC
    module Resources
        
        class Base < ActiveResource::Base
            
            attr_writer :uri
            
            self.format = :json
            
            class << self
              
              def structure_root(root)
                @structure_root = root
              end
              
              def get_structure_root()
                @structure_root || nil
              end
              
              def instantiate_collection(collection, prefix_options = {})
                collection.collect! { |record| instantiate_record(record, prefix_options) }
              end
              
              def instantiate_record(record, prefix_options = {}, path = nil)
                new(record).tap do |resource|
                  resource.prefix_options = prefix_options
                  resource.uri = path
                end
              end
              
              private
                
                def find_every(options)
                  case from = options[:from]
                  when Symbol
                    instantiate_collection(get(from, options[:params]))
                  when String
                    path = "#{from}#{query_string(options[:params])}"
                    instantiate_collection(connection.get(path, headers) || [])
                  else
                    prefix_options, query_options = split_options(options[:params])
                    path = collection_path(prefix_options, query_options)
                    instantiate_collection( (connection.get(path, options[:headers] || {}) || []), prefix_options )
                  end
                end
                
                
                # Find a single resource from a one-off URL
                def find_one(options)
                  path = "#{from}#{query_string(options[:params])}"
                  case from = options[:from]
                  when Symbol
                    instantiate_record(get(from, options[:params]), {}, path)
                  when String
                    
                    instantiate_record(connection.get(path, options[:headers] || {}), {}, path)
                  end
                end

                # Find a single resource from the default URL
                def find_single(scope, options)
                  prefix_options, query_options = split_options(options[:params])
                  path = element_path(scope, prefix_options, query_options)
                  instantiate_record(connection.get(path, options[:headers] || {}), prefix_options, path)
                end

              
              
            end
            
            def structure_root
              self.class.get_structure_root().to_s || element_name.to_s
            end
            
            def id
                uri.split('/').reverse.find {|token| token =~ /^\d+$/} unless uri.nil?
            end
            
            def uri
              link_to_self = links.attributes['self'] if respond_to? :links
              return link_to_self unless link_to_self.nil?
              return @uri unless @uri.nil?
              
            end
             
            def root
              attributes[structure_root]
            end
            
            def load(attributes)
              raise ArgumentError, "expected an attributes Hash, got #{attributes.inspect}" unless attributes.is_a?(Hash)
              @prefix_options, attributes = split_options(attributes)
              attributes.each do |key, value|
                @attributes[key.to_s] = process_key(key, value)
              end
              self
            end
            
            
            
            private
            def process_key(key, value)
              case key
                when 'meta'
                  create_meta(value)
                when 'links'
                  create_links(value)
                else
                  process_value(key, value)
              end
            end
            
            def create_meta(value)
              Meta.new(value)
            end
            
            def create_links(value)
              Links.new(value)
            end
            
            def process_value(key, value)
                case value
                  # when Array
                    # resource = find_or_create_resource_for_collection(key)
                    # value.map { |attrs| attrs.is_a?(String) ? attrs.dup : resource.new(attrs) }
                  when Hash
                      new_hash = {}
                      value.each do |key, value|
                        new_hash[key.to_s] = process_key(key, value)
                      end
                      new_hash
                  else
                    value.dup rescue value
                end
            end
            
            def process_hash(key, value)
                new_hash = {}
                new_hash[key.to_s] =
                case key
                when "meta"
                    Meta.new(value)
                when Hash
                    value.each do |key, value|
                        new_hash[key.to_s] = process_hash(key, value)
                    end
                end
            end
            
            def method_missing(method_symbol, *arguments) #:nodoc:
              method_name = method_symbol.to_s

              case method_name.last
                when "="
                  root[method_name.first(-1)] = arguments.first
                when "?"
                  root[method_name.first(-1)]
                else
                  root.has_key?(method_name) ? root[method_name] : super
              end
            end
            
            
        end
    end
end
