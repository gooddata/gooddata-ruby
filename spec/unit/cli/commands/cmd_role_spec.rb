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
      it 'Complains when no project ID specified' do
        args = %w(role list)

        out = run_cli(args)
        out.should include 'Project ID has to be provided'
      end

      it 'List roles when passing project ID' do
        args = [
          '-p',
          ProjectHelper::PROJECT_ID,
          'role',
          'list',
        ]

        out = run_cli(args)
        out.should include 'dashboardOnlyRole,/gdc/projects/la84vcyhrq8jwbu4wpipw66q2sqeb923/roles/3'
        out.should include 'readOnlyUserRole,/gdc/projects/la84vcyhrq8jwbu4wpipw66q2sqeb923/roles/7'
      end
    end
  end
end