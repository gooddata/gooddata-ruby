# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe Enumerable do
  describe '#pmap' do
    it 'should work like #map but in parallel' do
      input = [1, 2, 3]
      output = input.pmap { |item| item + 1 }
      expect(output).to eq input.map { |item| item + 1 }
    end
  end

  describe '#peach' do
    it 'should work like #each but in parallel' do
      input = [1, 2, 3]
      output = Concurrent::Array.new
      input.peach { |item| output << (item + 1) }
      expect(output).to eq [2, 3, 4]
    end
  end

  describe '#flat_pmap' do
    it 'should work like #flat_map but in parallel' do
      input = [['a'], ['b'], ['c']]
      output = input.flat_pmap { |item| item + ['X'] }
      expect(output).to eq input.flat_map { |item| item + ['X'] }
    end
  end
end
