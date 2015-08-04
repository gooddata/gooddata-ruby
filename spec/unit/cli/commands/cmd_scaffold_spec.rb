# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'fileutils'

require 'gooddata/cli/cli'

describe 'GoodData::CLI - scaffold', :broken => true do
  TEST_PROJECT_NAME = 'test-project'
  TEST_BRICK_NAME = 'test-brick'

  describe 'scaffold' do
    it 'Complains when no subcommand specified' do
      args = %w(scaffold)

      out = run_cli(args)
      out.should include "Command 'scaffold' requires a subcommand project,brick"
    end
  end

  describe 'scaffold brick' do
    it 'Complains when brick name is not specified' do
      args = %w(scaffold brick)

      out = run_cli(args)
      out.should include 'Name of the brick has to be provided'
    end

    it 'Scaffolds brick if the name is specified' do
      args = [
        'scaffold',
        'brick',
        TEST_BRICK_NAME
      ]

      run_cli(args)
      FileUtils.rm_rf(TEST_BRICK_NAME)
    end
  end

  describe 'scaffold project' do
    it 'Complains when project name is not specified' do
      args = %w(scaffold project)

      out = run_cli(args)
      out.should include 'Name of the project has to be provided'
    end

    it "Scaffolds project if the name is specified" do
      args = [
        'scaffold',
        'project',
        TEST_PROJECT_NAME
      ]

      run_cli(args)
      FileUtils.rm_rf(TEST_PROJECT_NAME)
    end
  end

end
