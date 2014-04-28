# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'domain' command" do
    args = %w(domain)

    out = run_cli(args)
    out.should include "Command 'domain' requires a subcommand add_user,list_users"
  end

  describe "domain add_user" do
    TEST_DOMAIN = 'gooddata'
    TEST_FIRSTNAME = 'joe'
    TEST_LASTNAME = 'doe'
    TEST_EMAIL = 'joe.doe@gooddata.com'
    TEST_PASSWORD = 'p4ssw0rth'

    it "Outputs 'Domain name has to be provided' if none specified" do
      args = %w(domain add_user)

      out = run_cli(args)
      out.should include 'Domain name has to be provided'
    end

    it "Outputs 'Firstname has to be provided' if none specified" do
      args = [
        'domain',
        'add_user',
        TEST_DOMAIN
      ]

      out = run_cli(args)
      out.should include 'Firstname has to be provided'
    end

    it "Outputs 'Lastname has to be provided' if none specified" do
      args = [
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_FIRSTNAME
      ]

      out = run_cli(args)
      out.should include 'Lastname has to be provided'
    end

    it "Outputs 'Email has to be provided' if none specified" do
      args = [
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_FIRSTNAME,
        TEST_LASTNAME
      ]

      out = run_cli(args)
      out.should include 'Email has to be provided'
    end

    it "Outputs 'Password has to be provided' if none specified" do
      args = [
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_FIRSTNAME,
        TEST_LASTNAME,
        TEST_EMAIL
      ]

      out = run_cli(args)
      out.should include 'Password has to be provided'
    end

    it 'Works' do
      args = [
        'domain',
        'add_user',
        TEST_DOMAIN,
        TEST_FIRSTNAME,
        TEST_LASTNAME,
        TEST_EMAIL,
        TEST_PASSWORD
      ]

      out = run_cli(args)
    end

  end

  describe 'domain list_users' do
    it 'Complains when no parameters specified' do
      args = %w(domain list_users)

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