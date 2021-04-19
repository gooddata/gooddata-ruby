# (C) 2019-2020 GoodData Corporation
require_relative '../../support/constants'
require_relative '../../support/configuration_helper'
require_relative '../../support/lcm_helper'
require_relative '../brick_runner'
require_relative '../shared_contexts_for_lcm'

# global variables to simplify passing stuff between shared contexts and examples
$master_projects = []
$client_projects = []
$master_before = false
$master_after = false

schedule_additional_hidden_params = {
    hidden_msg_from_release_brick: 'Hi, I was set by a brick but keep it secret',
    SECURE_PARAM_2: 'I AM SET TOO'
}

process_additional_hidden_params = {
    process: {
        component: {
            configLocation: {
                s3: {
                    path: 's3://s3_bucket/s3_folder/',
                    accessKey: 's3_access_key',
                    secretKey: 's3_secret_key',
                    serverSideEncryption: true
                }
            }
        }
    }
}

describe 'the whole life-cycle upgrade custom v2', :vcr do
  include_context 'lcm bricks',
                  schedule_additional_hidden_params: schedule_additional_hidden_params,
                  process_additional_hidden_params: process_additional_hidden_params

  describe '1 - Upgrade custom v2 date dimensions' do
    before(:all) do
      json = File.read('./spec/lcm/integration/data/model_upgrade_v2_date.json')
      blueprint = GoodData::Model::ProjectBlueprint.from_json(json)
      @project.update_from_blueprint(
          blueprint,
          update_preference: {
              allow_cascade_drops: true,
              keep_data: false
          },
          exclude_fact_rule: true,
          execute_ca_scripts: false,
          include_deprecated: false
      )

      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick.json.erb', client: @prod_rest_client
      $client_projects = BrickRunner.provisioning_brick context: @test_context, template_path: '../../params/provisioning_brick.json.erb', client: @prod_rest_client
      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../../params/rollout_brick.json.erb', client: @prod_rest_client

      $master_before = $master_projects.first

      message = GoodData::LCM2::MigrateGdcDateDimension::get_upgrade_message(false, %w[datecustomupgrade.dataset.dt dategooddata.dataset.dt])
      @project.upgrade_custom_v2(message)
      $master_projects = BrickRunner.release_brick context: @test_context, template_path: '../../params/release_brick.json.erb', client: @prod_rest_client
      $master_after = $master_projects.first
      $client_projects = BrickRunner.rollout_brick context: @test_context, template_path: '../../params/rollout_brick.json.erb', client: @prod_rest_client
    end

    it 'migrates LDM' do
      old_blueprint = GoodData::Model::ProjectBlueprint.new($master_before.blueprint)
      master_blueprint = GoodData::Model::ProjectBlueprint.new($master_after.blueprint)
      master_dates = GoodData::LCM2::MigrateGdcDateDimension::get_date_dimensions(master_blueprint);
      old_dates = GoodData::LCM2::MigrateGdcDateDimension::get_date_dimensions(old_blueprint);
      $client_projects.each do |target_project|
        client_blueprint = GoodData::Model::ProjectBlueprint.new(target_project.blueprint)
        client_dates = GoodData::LCM2::MigrateGdcDateDimension::get_date_dimensions(client_blueprint);

        expect(!(old_dates.any? { |old| old[:urn].include?(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2) })).to be_truthy
        expect(master_dates.any? { |old| old[:urn].include?(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2) }).to be_truthy

        master_dates.each do |date|
          expect(client_dates.any? { |client| client[:urn] == date[:urn] }).to be_truthy
          expect(client_dates.any? { |client| client[:id] == date[:id] }).to be_truthy
          if date[:id] == 'datecustomupgrade' || date[:id] == 'dategooddata'
            expect(date[:urn]).to eq(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2)
          end
        end

        expect(client_dates.any? { |client| client[:urn] == GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2 }).to be_truthy
        client_dates.each do |date|
          if date[:id] == 'datecustomupgrade' || date[:id] == 'dategooddata'
            expect(date[:urn]).to eq(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2)
          end
        end
      end
    end
  end
end




