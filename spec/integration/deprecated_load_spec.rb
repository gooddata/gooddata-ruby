# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Full project implementation", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper::create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.build("my_bp") do |p|
      p.add_dataset("dataset.repos") do |d|
        d.add_anchor("attr.repository")
        d.add_label('label.repository.name', reference: 'attr.repository')
        d.add_attribute("attr.attribute1", title: 'Some attribute')
        d.add_label('label.attribute1.name', reference: 'attr.attribute1')
        d.add_fact('some_numbers', gd_data_type: 'INT')
      end
    end

    @project = @client.create_project_from_blueprint(@blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:all) do
    @project.delete unless @project.nil?
    @client.disconnect
  end

  it 'should upload data using local blueprint' do
    devs_data = [
      ["label.repository.name", "label.attribute1.name", "some_numbers"],
      [1, "tomas@gooddata.com", 10],
      [2, "petr@gooddata.com", 20],
      [3, "jirka@gooddata.com", 30]]
    @project.upload(devs_data, @blueprint, 'dataset.repos')
    vals = @project.labels('label.repository.name').values.to_a.map {|l| l[:value]}
    expect(vals).to eq ["1", "2", "3"]
  end

  it 'should upload the data when you deprecate attribute with remote blueprint' do
    l = @project.labels('label.repository.name')
    l.deprecated = true
    l.save
    b = @project.labels(l.identifier)
    expect(b.deprecated?).to be_truthy

    devs_data = [
      ["label.repository.name", "label.attribute1.name", "some_numbers"],
      [1, "tomas@gooddata.com", 10],
      [2, "petr@gooddata.com", 20],
      [3, "jirka@gooddata.com", 30],
      [4, "jindrich@gooddata.com", 40]]
    @project.upload(devs_data, @project.blueprint, 'dataset.repos')
    vals = @project.labels('label.repository.name').values.to_a.map {|l| l[:value]}
    expect(vals).to eq ["1", "2", "3", "4"]
  end
end