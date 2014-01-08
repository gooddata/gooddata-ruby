module GoodData::Command
  class Profile
    class << self
      def show
        GoodData.profile.to_json
      end
    end
  end
end