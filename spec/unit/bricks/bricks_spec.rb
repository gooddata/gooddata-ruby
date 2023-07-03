# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/bricks'

describe GoodData::Bricks::Brick do
  it "Has GoodData::Bricks::Brick class" do
    expect(GoodData::Bricks::Brick).not_to be_nil
  end

  describe '#version' do
    it 'Throws NotImplemented on base class' do
      brick = GoodData::Bricks::Brick.new
      expect do
        brick.version
      end.to raise_error(NotImplementedError)
    end
  end

  it "should be possible to execute custom brick" do
    class CustomBrick < GoodData::Bricks::Brick
      def call(_params)
        puts 'hello'
      end
    end

    p = GoodData::Bricks::Pipeline.prepare([CustomBrick])

    p.call({})
  end
end
