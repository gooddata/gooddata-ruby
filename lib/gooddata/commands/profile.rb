module Gooddata::Command
  class Profile < Base
    def show
      pp gooddata.profile.to_json
    end
    alias :index :show
  end
end