# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Over-To data permissions implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/blueprints/m_n_model.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    @project = @client.create_project_from_blueprint(@blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    @label = @project.attributes('attr.permission.id').label_by_name('label.permission.id.email')

    data = [
      ['label.commits.id', 'fact.commits.lines_changed', 'dataset.users'],
      [1, 1, 1],
      [2, 3, 2],
      [3, 5, 3]]
    @project.upload(data, @blueprint, 'dataset.commits')
    
    data = [
      ["label.users.id", "label.users.id.email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    @project.upload(data, @blueprint, 'dataset.users')

    data = [
      ["label.permission.id", "label.permission.id.email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    @project.upload(data, @blueprint, 'dataset.permission_users')

    data = [
      ['label.visibility.id', 'dataset.permission_users', 'dataset.commits'],
      [1, 1, 1],
      [3, 1, 3]]
    @project.upload(data, @blueprint, 'dataset.visibility')

    @variable = @project.create_variable(title: 'uaaa', attribute: @label.attribute).save

    @attr1 = @project.attributes('attr.visibility.id')
    @attr2 = @project.attributes('attr.commits.id')

    @filters = [
      {
        login: ConnectionHelper::DEFAULT_USERNAME,
        filters: [
          { label: @label.uri, values: ["tomas@gooddata.com"], over: @attr1.uri, to: @attr2.uri}
        ]
      }
    ]
  end

  after(:all) do
    @project.delete if @project
  end

  after(:each) do
    @project.data_permissions.pmap &:delete
  end

  it "should fail if you are specifying OVER TO filter and variables. Variables do not support OVER TO" do
    expect do
      @project.add_variable_permissions(@filters, @variable)
    end.to raise_exception
  end

  it "should create an over to filter transparently" do    
    metric = @project.create_metric("SELECT SUM(#\"Fact.Commits.Lines Changed\")", :title => 'x')
    expect(metric.execute).to eq 9
    @project.add_data_permissions(@filters)
    expect(metric.execute).to eq 6

    r = @project.compute_report(left: [metric], top: ['label.users.id.email'])
    expect(r.include_column?(['tomas@gooddata.com', 1])).to eq true
    expect(r.include_column?(['jirka@gooddata.com', 5])).to eq true
    expect(r.include_column?(['petr@gooddata.com', 3])).to eq false

    data = [['label.visibility.id', 'dataset.permission_users', 'dataset.commits'], [1, 1, 1]]
    @project.upload(data, @blueprint, 'dataset.visibility')

    expect(metric.execute).to eq 1
    r = @project.compute_report(left: [metric], top: ['label.users.id.email'])
    expect(r.include_column?(['tomas@gooddata.com', 1])).to eq true
    expect(r.include_column?(['jirka@gooddata.com', 5])).to eq false
    expect(r.include_column?(['petr@gooddata.com', 3])).to eq false
  end
end
