# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it 'Has GoodData::CLI class' do
    GoodData::CLI.should_not == nil
  end

  it 'Has GoodData::CLI::main() working' do
    run_cli
  end
end