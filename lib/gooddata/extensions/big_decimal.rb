# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'bigdecimal'

module BigDecimalExtensions
  refine BigDecimal do
    def duplicable?
      true
    end

    def pretty_print(p)
      p.text to_s
    end
  end
end
