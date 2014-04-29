# encoding: UTF-8

require 'gooddata/cli/cli'

describe GoodData::CLI do
  describe 'role' do
    it 'Complains when no parameters specified' do
      args = %w(role)

      out = run_cli(args)
      out.should include "Command 'role' requires a subcommand list"
    end

    describe 'role list' do
      it 'Complains when no project_id specified' do
        args = %w(role list)

        out = run_cli(args)
        out.should include 'Project ID has to be provided'
      end

      it 'Works when valid project ID specified' do
        args = [
          '-p',
          'la84vcyhrq8jwbu4wpipw66q2sqeb923',
          'role',
          'list'
        ]

        out = run_cli(args)
      end
    end
  end
end