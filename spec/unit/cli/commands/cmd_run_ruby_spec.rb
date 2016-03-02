# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/cli/cli'

describe 'GoodData::CLI - run_ruby', :broken => true do
  describe 'run_ruby' do
    it 'Can be called without arguments' do
      args = %w(run_ruby)

      run_cli(args)
    end
  end
end