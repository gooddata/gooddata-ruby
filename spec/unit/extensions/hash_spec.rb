# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe Hash do
  describe '#deep_dup' do
    it 'should crete a deep copy' do
      x = {
        :a => {
          :b => :c
        }
      }
      y = x.dup
      deep_y = GoodData::Helpers.deep_dup(x)

      expect(y[:a].object_id).to be == x[:a].object_id
      expect(deep_y[:a].object_id).not_to be == x[:a].object_id
    end
  end
end
