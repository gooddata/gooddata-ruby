# encoding: UTF-8

module GoodData
  module Mixin
    module MdIdToUri
      IDENTIFIERS_CFG = 'instance-identifiers'
      
      # TODO: Add test
      def identifier_to_uri(*ids)
        fail(NoProjectError, 'Connect to a project before searching for an object') unless GoodData.project
        uri = GoodData.project.md[IDENTIFIERS_CFG]
        response = GoodData.post uri, 'identifierToUri' => ids
        if response['identifiers'].empty?
          nil
        else
          identifiers = response['identifiers']
          ids_lookup = identifiers.reduce({}) do |a, e|
            a[e['identifier']] = e['uri']
            a
          end
          uris = ids.map { |x| ids_lookup[x] }
          uris.count == 1 ? uris.first : uris
        end
      end

      alias_method :id_to_uri, :identifier_to_uri
    end
  end
end
