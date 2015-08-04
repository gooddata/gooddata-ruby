# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

class Object
  def blank?
    respond_to?(:empty?) ? empty? : !self
  end

  def duplicable?
    true
  end
end
