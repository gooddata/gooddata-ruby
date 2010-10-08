module Gooddata::Command
  class Version < Base
    def index
      puts Gooddata::Client.gem_version_string
    end
  end
end
