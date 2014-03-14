# Global requires
require 'json'

# Local requires
require 'gooddata/models/models'

module BlueprintHelper
  def blueprint_from_file(bp)
    # Try to load as full path
    raw = IO.read(bp)

    # TODO: Try to load as relative path if failed

    parsed = JSON.parse(raw, :symbolize_names => true)
    return GoodData::Model::ProjectBlueprint.new(parsed)
  end
end
