# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
module StringExtensions
  refine String do
    def to_b
      return true if self == true || self =~ (/(true|t|yes|y|1)$/i)
      return false if self == false || blank? || self =~ (/(false|f|no|n|0)$/i)
      raise ArgumentError, "invalid value for Boolean: \"#{self}\""
    end
  end
end
