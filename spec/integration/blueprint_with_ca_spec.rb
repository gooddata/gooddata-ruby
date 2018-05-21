# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe 'Create project using GoodData client with computed attribute', :vcr, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.build("My project from blueprint") do |project_builder|
      project_builder.add_dataset('dataset.users', title: 'Users Dataset') do |schema_builder|
        schema_builder.add_anchor('attr.users.id')
        schema_builder.add_label('label.users.id_label', reference: 'attr.users.id')
        schema_builder.add_attribute('attr.users.another_attr')
        schema_builder.add_label('label.users.another_attr_label', reference: 'attr.users.another_attr')
        schema_builder.add_fact('fact.users.some_number')
      end
    end
    fail "blueprint is invalid" unless @blueprint.valid?

    @project = @client.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
  end

  after(:all) do
    @project && @project.delete
    @client && @client.disconnect
  end

  it 'Should create computed attribute' do
    metric = @project.facts('fact.users.some_number').create_metric(title: 'Test')
    metric.save
    attribute = @project.attributes('attr.users.another_attr')

    update = GoodData::Model::ProjectBlueprint.build('update') do |project_builder|
      project_builder.add_computed_attribute(
        'attr.comp.my_computed_attr',
        title: 'My computed attribute',
        metric: metric,
        attribute: attribute,
        buckets: [{ label: 'Small', highest_value: 1000 }, { label: 'Medium', highest_value: 2000 }, { label: 'High' }]
      )
    end

    new_bp = @blueprint.merge(update)
    fail "blueprint with computed attribute is invalid" unless new_bp.valid?

    @project.update_from_blueprint(new_bp)
    ca = @project.attributes.find { |a| a.title == 'My computed attribute' }

    expect(ca).not_to be_nil
    expect(ca.computed_attribute?).to be_truthy
    expect(@project.computed_attributes.length).to eq 1
  end
end
