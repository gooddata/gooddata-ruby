module GoodData::Command
  class Version < Base
    def index
      puts GoodData::Client.gem_version_string
    end
  end
end
