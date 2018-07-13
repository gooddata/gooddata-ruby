# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
module IntegerExtensions
  refine Integer do
    def to_b
      self == 1
    end
  end
end
