# (C) 2019-2020 GoodData Corporation
require 'gooddata'

describe 'Should upgrade custom v2 for project', :vcr, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/old_date_dimension.json')
  end

  after(:all) do
    @client&.disconnect
  end

  it 'upgrade all date dimension to custom v2' do
    to_project = @client&.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::SECRETS[:gd_project_token], environment: ProjectHelper::ENVIRONMENT)
    blueprint = to_project.blueprint(include_ca: true)
    date_old = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)

    expect(date_old).not_to be_nil
    date_old.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      expect(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_OLD.any? { |e| date[:urn]&.include?(e) }).to be_truthy
    end

    message = GoodData::LCM2::MigrateGdcDateDimension::get_upgrade_message(true, nil)
    to_project&.upgrade_custom_v2(message)

    blueprint = to_project.blueprint(include_ca: true)
    date_new = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)
    expect(date_new).not_to be_nil
    date_new.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      expect(date[:urn]&.include?(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2)).to be_truthy
    end

    to_project&.delete
  end

  it 'upgrade a date dimension to custom v2' do
    to_project = @client&.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::SECRETS[:gd_project_token], environment: ProjectHelper::ENVIRONMENT)
    blueprint = to_project.blueprint(include_ca: true)
    date_old = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)

    expect(date_old).not_to be_nil
    date_old.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      expect(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_OLD.any? { |e| date[:urn]&.include?(e) }).to be_truthy
    end

    message = GoodData::LCM2::MigrateGdcDateDimension::get_upgrade_message(false, ['datecustom.dataset.dt'])
    to_project&.upgrade_custom_v2(message)

    blueprint = to_project.blueprint(include_ca: true)
    date_new = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)
    expect(date_new).not_to be_nil
    date_new.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      if date[:id] == 'datecustom'
        expect(date[:urn]&.include?(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2)).to be_truthy
      else
        expect(date[:urn]&.include?('gooddata')).to be_truthy
      end
    end

    to_project&.delete
  end

  it 'upgrade multiple date dimension to custom v2' do
    to_project = @client&.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::SECRETS[:gd_project_token], environment: ProjectHelper::ENVIRONMENT)
    blueprint = to_project.blueprint(include_ca: true)
    date_old = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)

    expect(date_old).not_to be_nil
    date_old.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      expect(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_OLD.any? { |e| date[:urn]&.include?(e) }).to be_truthy
    end

    message = GoodData::LCM2::MigrateGdcDateDimension::get_upgrade_message(false, ['datecustom.dataset.dt','dategooddata.dataset.dt'])
    to_project&.upgrade_custom_v2(message)

    blueprint = to_project.blueprint(include_ca: true)
    date_new = GoodData::Model::ProjectBlueprint.date_dimensions(blueprint)
    expect(date_new).not_to be_nil
    date_new.each do |date|
      expect(%w[datecustom dategooddata].any? { |e| date[:id] == e }).to be_truthy
      expect(date[:urn]&.include?(GoodData::LCM2::MigrateGdcDateDimension::DATE_DIMENSION_CUSTOM_V2)).to be_truthy
    end

    to_project&.delete
  end

end
