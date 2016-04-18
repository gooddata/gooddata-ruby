# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class ProjectMetadata
    class << self
      def keys(opts = { :client => GoodData.connection, :project => GoodData.project })
        ProjectMetadata[:all, opts].keys
      end

      def [](key, opts = { :client => GoodData.connection, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(opts)

        if key == :all
          uri = "/gdc/projects/#{project.pid}/dataload/metadata"
          res = client.get(uri)
          res['metadataItems']['items'].reduce({}) do |memo, i|
            memo[i['metadataItem']['key']] = i['metadataItem']['value']
            memo
          end
        else
          uri = "/gdc/projects/#{project.pid}/dataload/metadata/#{key}"
          res = client.get(uri)
          res['metadataItem']['value']
        end
      end

      alias_method :get, :[]
      alias_method :get_key, :[]

      def key?(key, opts = { :client => GoodData.connection, :project => GoodData.project })
        ProjectMetadata[key, opts]
        true
      rescue RestClient::ResourceNotFound
        false
      end

      def []=(key, opts = { :client => GoodData.connection, :project => GoodData.project }, val = nil)
        client, project = GoodData.get_client_and_project(opts)

        data = {
          :metadataItem => {
            :key => key,
            :value => val
          }
        }
        uri = "/gdc/projects/#{project.pid}/dataload/metadata/"
        update_uri = uri + key

        if key?(key, opts)
          client.put(update_uri, data)
        else
          client.post(uri, data)
        end
      end
    end
  end
end
