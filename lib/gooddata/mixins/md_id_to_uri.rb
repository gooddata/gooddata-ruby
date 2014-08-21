# encoding: UTF-8

module GoodData
  module Mixin
    module MdIdToUri
      IDENTIFIERS_CFG = 'instance-identifiers'

      # TODO: Add test
      def identifier_to_uri(opts = { :client => GoodData.connection, :project => GoodData.project }, *ids)
        client = opts[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        uri = project.md[IDENTIFIERS_CFG]
        response = client.post uri, 'identifierToUri' => ids
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
