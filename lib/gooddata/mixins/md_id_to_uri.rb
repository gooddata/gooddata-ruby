# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module MdIdToUri
      IDENTIFIERS_CFG = 'instance-identifiers'

      def identifier_to_uri(opts = { :client => GoodData.connection, :project => GoodData.project }, *ids)
        client, project = GoodData.get_client_and_project(opts)

        response = nil
        begin
          uri = project.md[IDENTIFIERS_CFG]
          response = client.post(uri, 'identifierToUri' => ids)
        rescue => ex
          raise ex
        end

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
