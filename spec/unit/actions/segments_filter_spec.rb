# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/actions/segments_filter'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::SegmentsFilter do
  context 'when segments contains duplicate segment ids' do
    let(:params) do
      params = {
        segments: [
          { segment_id: 'segment_foo' },
          { segment_id: 'Segment_foo' }
        ]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'raise error' do
      expect { subject.class.call(params) }.to raise_error(/segment_foo/, /Segment_foo/)
    end
  end

  context 'when passed segments' do
    let(:params) do
      params = {
        segments: [
          { segment_id: 'correct-segment' },
          { segment_id: 'wrong-segment' }
        ],
        segments_filter: [
          'correct-segment'
        ]
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'filters the segments according to segments_filter' do
      results = subject.class.call(params)
      expect(results[:results].first.segment_id).to eq 'correct-segment'
    end
  end
end
