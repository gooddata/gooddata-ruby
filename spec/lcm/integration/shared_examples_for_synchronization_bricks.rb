require_relative 'support/comparison_helper'

shared_examples 'a synchronization brick' do
  it 'transfers projects' do
    expect(projects).not_to be_empty
  end

  it 'transfers additional hidden parameters' do
    title = Support::RUBY_HELLO_WORLD_PROCESS_NAME
    projects.each do |project|
      process = project.processes.find { |p| p.name == title }
      schedule = process.schedules.first
      a = schedule.hidden_params
      expect(schedule.hidden_params.keys.map(&:to_sym)).to include(*@brick_result[:params][:additional_hidden_params].keys.map(&:to_sym))
    end
  end

  it 'migrates processes' do
    original_processes = original_project.processes.to_a
    expect(original_processes.length).to be 3
    projects.each do |target_project|
      target_processes = target_project.processes.to_a
      expect(target_processes.length).to be original_processes.length
      original_processes.each do |expected|
        actual = target_processes.find { |p| p.name == expected.name }
        expect(actual).not_to be_nil
        diff = Support::ComparisonHelper.compare_processes(expected, actual)
        expect(diff).to be_empty
      end
    end
  end

  it 'migrates user groups' do
    if user_group
      projects.each do |target_project|
        ug = target_project.user_groups.find { |ug| ug.name == Support::USER_GROUP_NAME }
        expect(ug).not_to be_nil
      end
    end
  end

  it 'migrates LDM' do
    projects.each do |target_project|
      blueprint = GoodData::Model::ProjectBlueprint.new(original_project.blueprint)
      diff = Support::ComparisonHelper.compare_ldm(blueprint, target_project.pid, @prod_rest_client)
      expect(diff['updateOperations']).to eq(update_operations)
      expect(diff['updateScripts']).to eq(update_scripts)
    end
  end

  it 'transfer computed attributes' do
    projects.each do |p|
      expect(p.computed_attributes.length).to be 1
    end
  end

  it 'transfer tags for facts and datasets' do
    projects.each do |p|
      expect(p.datasets(Support::DATASET_IDENTIFIER).tags.split).to include('dataset')
      expect(p.facts(Support::FACT_IDENTIFIER).tags.split).to include('fact')
    end
  end

  it 'migrates label types' do
    original_attributes = original_project.attributes.to_a
    new_attributes = projects && projects[0].attributes.to_a
    expect(original_attributes.length).to be 32
    expect(new_attributes.length).to be 32
    original_attributes.each do |attribute|
      next unless attribute.content['displayForms'] &&
      attribute.content['displayForms'].any?
      new_attribute = new_attributes.find do |a|
        a.identifier == attribute.identifier
      end
      label_type = attribute.content['displayForms'].first['content']['type']
      new_label_type = new_attribute.content['displayForms'].first['content']['type']
      expect(new_label_type).to eq label_type
    end
  end

  it 'migrates schedules' do
    original_schedules = original_project.schedules.to_a
    expect(original_schedules.length).to be 3
    projects.each do |target_project|
      target_schedules = target_project.schedules
      expect(target_schedules.all? { |sch| sch.state == schedules_status }).to be_truthy
      expect(original_schedules.length).to be target_schedules.length
      original_schedules.each do |expected|
        actual = target_schedules.find { |d| d.name == expected.name }
        expect(actual).not_to be_nil
        diff = Support::ComparisonHelper.compare_schedules(expected, actual)
        expect(diff).to match_array(schedule_diff)
      end
    end
  end

  it 'migrates dashboards' do
    original_dashboards = original_project.dashboards.to_a
    projects.each do |target_project|
      target_dashboards = target_project.dashboards.to_a
      expect(original_dashboards.length).to be target_dashboards.length
      original_dashboards.each do |expected|
        actual = target_dashboards.find { |d| d.title == expected.title }
        expect(actual).not_to be_nil
        diff = Support::ComparisonHelper.compare_dashboards(expected, actual)
        expected_diff = []
        expected_diff << ['~', 'meta.tags', 'dashboard', '_lcm_managed_object dashboard'] if lcm_managed_tag
        expect(diff).to eq expected_diff
      end
    end
  end

  it 'migrates reports used in dashboards' do
    original_reports = original_project.reports.to_a
    used_reports_titles = ['Customers Count By State', 'Customers Count By Gender', 'Report contains CA']
    expected_reports = original_reports.find_all do |r|
      used_reports_titles.include?(r.title)
    end
    expect(expected_reports.length).to be 3
    projects.each do |target_project|
      target_reports = target_project.reports.to_a
      expect(target_reports.length).to be expected_reports.length
      expected_reports.each do |expected|
        actual = target_reports.find { |r| r.title == expected.title }
        expect(actual).not_to be_nil
        diff = Support::ComparisonHelper.compare_reports(expected, actual)
        expected_diff = []
        expected_diff << ['~', 'meta.tags', '', '_lcm_managed_object'] if lcm_managed_tag
        expect(diff).to eq(expected_diff)
      end
    end
  end

  it 'migrates metrics' do
    used_in_dashboard = 'metric.customers.count'
    tagged_production = Support::PRODUCTION_TAGGED_METRIC
    expected_metrics = [used_in_dashboard, tagged_production]
    projects.each do |target_project|
      expect(target_project.metrics.map(&:identifier)).to match_array(expected_metrics)
    end
  end

  it 'migrates drill path' do
    drill_target_attr_id = 'attr.csv_policies.customer'
    projects.each do |target_project|
      ca = target_project.attributes(Support::COMPUTED_ATTRIBUTE_ID)
      drill_target_attr = target_project.attributes(drill_target_attr_id)
      expect(target_project.labels(ca.content['drillDownStepAttributeDF']).attribute_uri).to eq drill_target_attr.uri
    end
  end

  it 'does not migrate variables' do
    projects.each do |project|
       expect(project.variables.to_a).to be_empty
    end
  end
end
