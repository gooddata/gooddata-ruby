module GDC
  module Resources
    class Links

      attr_reader :attributes

      def initialize(data)
        @attributes = data
      end

      def to_json(options = {})
        attributes.to_json(options)
      end

      def to_xml(options = {})
        attributes.to_xml(options)
      end
      
      def method_missing(method_symbol, *arguments) #:nodoc:
        method_name = method_symbol.to_s
        
        case method_name.last
          when "="
            attributes[method_name.first(-1)] = arguments.first
          when "?"
            attributes[method_name.first(-1)]
          else
            attributes.has_key?(method_name) ? attributes[method_name] : super
        end
      end
      
    end
  end
end