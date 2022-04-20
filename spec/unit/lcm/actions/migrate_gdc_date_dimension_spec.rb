# frozen_string_literal: true
# (C) 2019-2022 GoodData Corporation
describe GoodData::LCM2::MigrateGdcDateDimension do
  before(:all) do
    @project_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/old_date_dimension_source.json')
    @project_add_more_dd_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/old_date_dimension_add_more.json')
    @project_remove_dd_blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/old_date_dimension_remove_some_one.json')
    @migrate_gdc_dd = GoodData::LCM2::MigrateGdcDateDimension
  end

  it 'get date from project' do
    existing_dd = @migrate_gdc_dd.get_date_dimension(@project_blueprint, 'datecustom')
    not_existing_dd = @migrate_gdc_dd.get_date_dimension(@project_blueprint, 'datecustomadd01')

    expect(existing_dd).to be_truthy
    expect(not_existing_dd).to be_falsey
  end

  it 'get upgrade dates list for adding more dates' do
    dates = @migrate_gdc_dd.get_upgrade_dates(@project_blueprint, @project_add_more_dd_blueprint)

    expect(dates.length).to eq 3
    expect(dates.include?('datecustom')).to be_truthy
    expect(dates.include?('dategooddata')).to be_truthy
    expect(dates.include?('targetdate')).to be_truthy
  end

  it 'get upgrade dates list for removing dates' do
    dates = @migrate_gdc_dd.get_upgrade_dates(@project_blueprint, @project_remove_dd_blueprint)

    expect(dates.length).to eq 1
    expect(dates.include?('targetdate')).to be_truthy
  end
end
