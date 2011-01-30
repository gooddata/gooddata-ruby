module GoodData::Command
  class Profile < Base
    def show
      connect
      pp GoodData.profile.to_json
    end
    alias :index :show
  end
end