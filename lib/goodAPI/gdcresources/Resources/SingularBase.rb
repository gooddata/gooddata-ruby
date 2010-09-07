module GDC
    module Resources
        class SingularBase < Base
            class << self
                def element_path(id, prefix_options = {}, query_options = nil)
                  prefix_options, query_options = split_options(prefix_options) if query_options.nil?
                  "#{prefix(prefix_options)}#{collection_name}/#{id}#{query_string(query_options)}"
                end

                def collection_path(prefix_options = {}, query_options = nil)
                    prefix_options, query_options = split_options(prefix_options) if query_options.nil?
                    "#{prefix(prefix_options)}#{collection_name}#{query_string(query_options)}"
                end
                
                attr_accessor_with_default(:collection_name) { element_name } #:nodoc:
                
            end

        end
    end
end

