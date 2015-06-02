# encoding: UTF-8

# Global requires
require 'multi_json'

# Local requires
require 'gooddata/models/models'

module GoodData::Helpers
  module BlueprintHelper
    def blueprint_from_file(bp)
      # Try to load as full path
      raw = IO.read(bp)

      # TODO: Try to load as relative path if failed

      parsed = MultiJson.load(raw, :symbolize_keys => true)
      return GoodData::Model::ProjectBlueprint.new(parsed)
    end
  end
end

