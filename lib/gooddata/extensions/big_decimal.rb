# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'bigdecimal'

class BigDecimal
  def duplicable?
    true
  end

  def pretty_print(p)
    p.text to_s
  end
end
