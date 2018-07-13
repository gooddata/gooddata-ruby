# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
module NumericExtensions
  refine Numeric do
    # Numbers are not duplicable:
    #
    #  3.duplicable? # => false
    #  3.dup         # => TypeError: can't dup Fixnum
    def duplicable?
      false
    end
  end
end
