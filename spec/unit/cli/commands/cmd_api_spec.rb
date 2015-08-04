# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/cli/cli'

describe 'GoodData::CLI - api', :broken => true do
  describe 'api' do
    it 'Complains when no subcommand specified' do
      args = %w(api)

      out = run_cli(args)
      out.should include("Command 'api' requires a subcommand info,get")
    end
  end

  describe 'api info' do
    it 'Can be called without arguments' do
      args = %w(api info)

      run_cli(args)
    end
  end

  describe 'api get' do
    it 'Can be called without arguments' do
      args = %w(api get)

      run_cli(args)
    end

    it 'Is able to get /gdc' do
      args = %w(api get /gdc)

      run_cli(args)
    end
  end
end