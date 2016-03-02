# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/cli/cli'

describe 'GoodData::CLI - domain', :broken => true do
  describe 'domain' do
    it 'Complains when no subcommand specified' do
      args = %w(domain)

      out = run_cli(args)
      out.should include "Command 'domain' requires a subcommand add_user,list_users"
    end
  end

  describe "domain add_user" do
    TEST_DOMAIN = 'gooddata'
    TEST_EMAIL = 'joe.doe@gooddata.com'
    TEST_PASSWORD = 'p4ssw0rth'

    it "Outputs 'Domain name has to be provided' if none specified" do
      args = [
        '-U',
         ConnectionHelper::DEFAULT_USERNAME,
         '-P',
         ConnectionHelper::DEFAULT_PASSWORD,
         'domain',
         'add_user'
      ]

      out = run_cli(args)
      out.should include 'Domain name has to be provided'
    end

    it "Outputs 'Email has to be provided' if none specified" do
      args = [
        '-U',
        ConnectionHelper::DEFAULT_USERNAME,
        '-P',
        ConnectionHelper::DEFAULT_PASSWORD,
        'domain',
        'add_user',
        TEST_DOMAIN
      ]

      out = run_cli(args)
      out.should include 'Email has to be provided'
    end

    it "Outputs 'Password has to be provided' if none specified" do
      args = [
        '-U',
        ConnectionHelper::DEFAULT_USERNAME,
        '-P',
        ConnectionHelper::DEFAULT_PASSWORD,
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_EMAIL
      ]

      out = run_cli(args)
      out.should include 'Password has to be provided'
    end

    it 'Works' do
      args = [
        '-U',
        ConnectionHelper::DEFAULT_USERNAME,
        '-P',
        ConnectionHelper::DEFAULT_PASSWORD,
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_EMAIL,
        TEST_PASSWORD
      ]

      out = run_cli(args)
    end

  end

  describe 'domain list_users' do
    it 'Complains when no parameters specified' do
      args = [
        '-U',
        ConnectionHelper::DEFAULT_USERNAME,
        '-P',
        ConnectionHelper::DEFAULT_PASSWORD,
        'domain',
        'list_users'
      ]

      out = run_cli(args)
      out.should include 'Domain name has to be provided'
    end

    it 'Works' do
      args = [
        'domain',
        'list_users',
        'gooddata'
      ]

      out = run_cli(args)
    end
  end
end