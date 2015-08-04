# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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

