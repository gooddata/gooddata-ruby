# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::LCM, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client && @client.disconnect
  end

  it 'should be able to transfer attribute drill paths' do
    begin
      spec = JSON.parse(File.read("./spec/data/blueprints/attribute_sort_order_blueprint.json"), :symbolize_names => true)
      blueprint = GoodData::Model::ProjectBlueprint.new(spec)

      source_project = @client.create_project_from_blueprint(blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
      target_project = @client.create_project_from_blueprint(source_project.blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)

      name_attribute_source = source_project.attributes('attr.id.name')
      id_attribute_source = source_project.attributes('attr.id.id')
      name_attribute_source.drill_down(id_attribute_source)

      GoodData::LCM.transfer_attribute_drillpaths(source_project, target_project)

      name_attribute_target = target_project.attributes('attr.id.name')
      id_attribute_target = target_project.attributes('attr.id.id')
      name_attribute_target.drill_down(id_attribute_target)
      expect(target_project.labels(name_attribute_target.content['drillDownStepAttributeDF']).attribute_uri).to eq id_attribute_target.meta['uri']
    ensure
      source_project && source_project.delete
      target_project && target_project.delete
    end
  end
end
