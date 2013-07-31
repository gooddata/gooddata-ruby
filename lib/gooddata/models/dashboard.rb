module GoodData
  class Dashboard < GoodData::MdObject 

    class << self
      def [](id)
        if id == :all
          GoodData.get(GoodData.project.md['query'] + '/projectDashboard/')['query']['entries']
        else 
          super
        end
      end
    end

    def export(format, options={})
      supported_formats = [:pdf]
      fail "Wrong format provied \"#{format}\". Only supports formats #{supported_formats.join(', ')}" unless supported_formats.include?(format)
      tab = options[:tab] || ""
      x = GoodData.post("/gdc/projects/#{GoodData.project.uri}/clientexport", {"clientExport" => {"url" => "https://secure.gooddata.com/dashboard.html#project=#{GoodData.project.uri}&dashboard=#{uri}&tab=#{tab}&export=1", "name" => title}}, :process => false)
      while (x.code == 202) do
        sleep(1)
        uri = JSON.parse(x.body)["asyncTask"]["link"]["poll"]
        x = GoodData.get(uri, :process => false)
      end
      x
    end

    def tabs
       content["tabs"]
    end

    def tabs_ids
      tabs.map {|t| t["identifier"]}
    end

  end
end
