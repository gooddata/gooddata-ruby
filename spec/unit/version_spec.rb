# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData do
  VERSION_REGEX = /\d+\.\d+\.\d+.*/

  it 'sdk_version' do
    expect(GoodData.sdk_version).to match(VERSION_REGEX)
  end

  it 'version' do
    expect(GoodData.version).to eq(GoodData.sdk_version)
  end

  it 'brick_version' do
    expect(GoodData.bricks_version).to match(VERSION_REGEX)
  end
end
