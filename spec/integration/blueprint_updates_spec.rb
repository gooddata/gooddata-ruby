# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe 'Create project using GoodData client', :constraint => 'slow' do
  before(:all) do    
    @client = ConnectionHelper.create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.from_json('./spec/data/blueprints/test_project_model_spec.json')
    @project = @client.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:all) do
    @project.delete
    @client.disconnect
  end

  it 'Should create project using GoodData::Rest::Client#create_project' do
  
    data = [
      ["repo_id", "repo_name"],
      [1, "goodot"],
      [2, "bam"],
      [3, "infra"]]
    @project.upload(data, @blueprint, 'dataset.repos')

    data = [
      ['dev_id', 'email'],
      ['1', 'tomas@gmail.com'],
      ['2', 'petr@gmail.com'],
      ['3', 'jirka@gmail.com']]
    @project.upload(data, @blueprint, 'dataset.devs')

    data = [
      ['lines_changed', 'committed_on', 'dev_id', 'repo_id'],
      [1, '01/01/2011', '1', '1'],
      [2, '01/01/2011', '2', '2'],
      [3, '01/01/2011', '3', '3']]
    @project.upload(data, @blueprint, 'dataset.commits')
  end

  it "should be able to add anchor's labels" do
    bp = @project.blueprint
    bp.datasets('dataset.commits').change do |d|
      d.add_label('label.commits.factsof.id',
        reference: 'attr.commits.factsof',
        name: 'anchor_label')
    end
    @project.update_from_blueprint(bp, preference: { cascade_drops: false,  preserve_data: false})
    data = [
      ['label.commits.factsof.id', 'fact.commits.lines_changed', 'committed_on', 'dataset.devs', 'dataset.repos'],
      ['111', 1, '01/01/2011', '1', '1'],
      ['222', 2, '01/01/2011', '2', '2'],
      ['333', 3, '01/01/2011', '3', '3']]
    @project.upload(data, bp, 'dataset.commits')
    m = @project.facts.first.create_metric
    @project.compute_report(top: [m], left: ['label.commits.factsof.id'])
  end

  it "be able to remove anchor's labels" do
    bp = @project.blueprint
    bp.datasets('dataset.commits').anchor.strip!
    @project.update_from_blueprint(bp)
    bp = @project.blueprint
    expect(bp.datasets('dataset.commits').anchor.labels.count).to eq 0
    expect(@project.labels('label.commits.factsof.id')).to eq nil
  end

  it "is possible to move attribute. Let's make a fast attribute." do
    # define stuff
    m = @project.facts.first.create_metric.save
    report = @project.create_report(title: 'Test report', top: [m], left: ['label.devs.dev_id.email'])
    #both compute
    expect(m.execute).to eq 6
    expect(report.execute.without_top_headers.to_a).to eq [['jirka@gmail.com', 3],
                                                           ['petr@gmail.com', 2],
                                                           ['tomas@gmail.com', 1]]

    # We move attribute
    @blueprint.move!('some_attr_id', 'dataset.repos', 'dataset.commits')
    @project.update_from_blueprint(@blueprint)

    # load new data
    data = [
      ['lines_changed', 'committed_on', 'dev_id', 'repo_id', 'repo_name'],
      [1, '01/01/2011', '1', '1', 'goodot'],
      [2, '01/01/2011', '2', '2', 'goodot'],
      [3, '01/01/2011', '3', '3', 'infra']]
    @project.upload(data, @blueprint, 'dataset.commits')

    # both still compute
    # since we did not change the grain the results are the same
    expect(m.execute).to eq 6
    expect(report.execute.without_top_headers.to_a).to eq [["jirka@gmail.com", 3],
                                                           ["petr@gmail.com", 2],
                                                           ["tomas@gmail.com", 1]]
  end
end
