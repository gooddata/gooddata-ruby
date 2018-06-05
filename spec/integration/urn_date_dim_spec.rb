# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Blueprint now support urn in date dimension", :vcr, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection

    @blueprint = GoodData::Model::ProjectBlueprint.build("My project from blueprint") do |p|
      p.add_date_dimension('created_on', urn: 'urn:pe:date')
    end
  end

  after(:all) do
    @client && @client.disconnect
  end

  context 'project creates from blueprint contains urn in date dimension' do
    before(:all) do
      @project = @client.create_project_from_blueprint(@blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    end

    after(:all) do
      @project && @project.delete
    end

    it 'should have urn in date dimension' do
      expect(@project.datasets.find(&:date_dimension?).content['urn']).to eq 'urn:pe:date'
    end

    it 'blueprint contains urn in date dimension' do
      expect(@project.blueprint.date_dimensions.first.urn).to eq 'urn:pe:date'
    end
  end

  context 'merging blueprint' do
    before do
      @new_bp = GoodData::Model::ProjectBlueprint.build("update") do |p|
        p.add_date_dimension('created_on', urn: 'urn:stonegate:date')
      end

      @blueprint = @blueprint.merge(@new_bp)
    end

    it 'update urn' do
      expect(@blueprint.date_dimensions.first.urn).to eq 'urn:stonegate:date'
    end
  end
end
