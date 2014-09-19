# encoding: UTF-8

module GoodData
  class ProjectMetadata
    class << self
      def keys(opts = { :client => GoodData.connection, :project => GoodData.project })
        ProjectMetadata[:all, opts].keys
      end

      def [](key, opts = { :client => GoodData.connection, :project => GoodData.project })
        client = opts[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        project = opts[:project]
        fail ArgumentError, 'No :project specified' if project.nil?

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
        client = opts[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        project = opts[:project]
        fail ArgumentError, 'No :project specified' if project.nil?

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
