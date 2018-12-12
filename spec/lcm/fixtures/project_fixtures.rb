require_relative 'base_fixtures'
require_relative '../integration/support/configuration_helper'
require_relative '../integration/support/connection_helper'
require_relative '../integration/support/project_helper'

module Fixtures
  class ProjectFixtures < BaseFixtures
    def initialize(opts = {})
      domain = opts[:domain]
      rest_client = opts[:rest_client]
      project_amount = opts[:project_amount] || 1
      suffix = ConfigurationHelper.suffix

      data_product = domain.create_data_product(id: FIXTURE_ID_PREFIX + suffix)
      master_project = rest_client.create_project(title: FIXTURE_ID_PREFIX + suffix, auth_token: LcmConnectionHelper.environment[:prod_token])
      segment = data_product.create_segment(segment_id: FIXTURE_ID_PREFIX + suffix, master_project: master_project)

      projects = project_amount.times.map do |n|
        opts = {
          client: rest_client,
          title: [FIXTURE_ID_PREFIX, suffix, n.to_s].join(' '),
          auth_token: LcmConnectionHelper.environment[:prod_token],
          environment: 'TESTING'
        }
        project_helper = Support::ProjectHelper.create(opts)
        puts 'creating LDM and stuff'
        project_helper.create_ldm
        project_helper.load_data
        puts "created project #{project_helper.project.pid}"
        project_helper.project
      end

      @teardown = lambda do
        (projects + [master_project]).map(&:delete)
        data_product.delete(force: true)
      end

      clients = Hash[projects.each_with_index.map do |project, i|
        [segment.create_client(id: FIXTURE_ID_PREFIX + i.to_s, project: project), project]
      end]

      @objects = {
        clients: clients,
        projects: projects,
        data_product: data_product,
        segment: segment
      }
    end
  end
end
