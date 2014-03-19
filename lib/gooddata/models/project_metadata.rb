# encoding: UTF-8

module GoodData
  class ProjectMetadata
    class << self
      def keys
        ProjectMetadata[:all].keys
      end

      def [](key)
        if key == :all
          uri = "/gdc/projects/#{GoodData.project.pid}/dataload/metadata"
          res = GoodData.get(uri)
          res['metadataItems']['items'].reduce({}) { |memo, i| memo[i['metadataItem']['key']] = i['metadataItem']['value']; memo }
        else
          uri = "/gdc/projects/#{GoodData.project.pid}/dataload/metadata/#{key}"
          res = GoodData.get(uri)
          res['metadataItem']['value']
        end
      end

      alias_method :get, :[]
      alias_method :get_key, :[]

      def has_key?(key)
        begin
          ProjectMetadata[key]
          true
        rescue RestClient::ResourceNotFound => e
          false
        end
      end

      def []=(key, val)
        data = {
          :metadataItem => {
            :key => key,
            :value => val
          }
        }
        uri = "/gdc/projects/#{GoodData.project.pid}/dataload/metadata/"
        update_uri = uri + key

        if has_key?(key)
          GoodData.put(update_uri, data)
        else
          GoodData.post(uri, data)
        end
      end
    end
  end
end
