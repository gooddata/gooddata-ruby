module GoodData::Command
  class Version < Base
    def index
      puts GoodData.gem_version_string
    end
  end
end
