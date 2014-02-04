module GoodData
  class ProjectMetadata

    class << self
      def [](key)
        if key == :all
          GoodData.get("/gdc/projects/#{GoodData.project.pid}/dataload/metadata")
        else 
          res = GoodData.get("/gdc/projects/#{GoodData.project.pid}/dataload/metadata/#{key}")
          res["metadataItem"]["value"]
        end
      end

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
