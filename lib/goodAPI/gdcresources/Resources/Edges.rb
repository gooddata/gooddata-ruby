module GDC
    module Resources
        class Edges < GDC::Resources::SingularBase
            
            class << self
              def ignore_nodes(an_array)
                @ignore_nodes = an_array
              end
              
              def get_ignore_nodes
                @ignore_nodes
              end
            end
            
            def edges
              attributes[structure_root]["edges"].map {|relation| Relation.new(relation)}
            end
            
            def nodes
              attributes[structure_root]["nodes"]
            end
            
            def grab_and_interpolate!(options = {})
              list = collect_obj_from_list(collect_node_uri(), options[:headers] || {})
              prune_node_keys!
              interpolate_nodes!(list)
            end
            
            def nodes=(an_array)
              # FIXME now just replacing one with another, this is bad, if we grab only some of the usedby resources. Need to iterate and comapre the uris to determine, if the resources are the same
              attributes[structure_root]["nodes"] = an_array
            end
            
            def collect_node_uri()
              list = nodes.find_all {|obj| !ignore?(obj['category'])}
              list.map {|obj| URI.parse(obj['link'])}
            end
            
            
            def collect_obj_from_list(list, headers)
              list_of_ids = list.collect {|uri| uri.to_s.split("/").last}
              list_of_ids.collect {|id| Obj.find(id, {:params => prefix_options, :headers => headers})}
            end
            
            def prune_node_keys!
              nodes.map do |node|
                node.slice!("category", "link") if !ignore?(node["category"])
              end
            end
            
            def enrich_node(node)
              node
                
            end
            
            def ignore?(node)
              
              result = ignore_nodes().include?(node)
              # puts "encountered #{node} and #{result}"
              result
            end
            
            def ignore_nodes
              self.class.get_ignore_nodes
            end
            
            def interpolate_nodes!(resources)
              self.nodes.each do |node|
                enriching_resource = resources.find {|obj| obj.uri === node["link"]}
                node.update(enriching_resource.root) if enriching_resource
              end
            end
        end
    end
end