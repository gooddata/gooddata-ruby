# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module MdJson
      def from_json(json)
        self.json = JSON.parse(json)
      end

      def to_json
        json.to_json
      end
    end
  end
end
