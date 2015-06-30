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
      ['dev_id', 'email'],
      ['1', 'tomas'],
      ['2', 'petr'],
      ['3', 'jirka']]
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
    skip('failing on server need to clear out with MSF')
    bp = @project.blueprint
    bp.datasets('dataset.commits').change do |d|
      d.add_label('label.commits.factsof.id',
        reference: 'attr.commits.factsof',
        name: 'anchor_label')
    end
    @project.update_from_blueprint(bp)
    data = [
      ['anchor_label', 'some_id_name', 'lines_changed', 'committed_on', 'dev_id', 'repo_id'],
      ['111', 1, 3, '01/01/2011', '1', '1'],
      ['222', 2, 9, '01/01/2011', '2', '2'],
      ['333', 3, 4, '01/01/2011', '3', '3']]
    @project.upload(data, @blueprint, 'dataset.commits')
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
    expect(report.execute.to_a).to eq [['jirka@gmail.com', 'petr@gmail.com', 'tomas@gmail.com'],
                                       [3.0, 2.0, 1.0]]

    # We move attribute
    @blueprint.move!('some_attr_id', 'dataset.repos', 'dataset.commits')
    @project.update_from_blueprint(@blueprint)

    # load new data
    data = [
      ['lines_changed', 'committed_on', 'dev_id', 'repo_id', 'email'],
      [1, '01/01/2011', '1', '1', 'tomas'],
      [2, '01/01/2011', '2', '2', 'petr'],
      [3, '01/01/2011', '3', '3', 'jirka']]
    @project.upload(data, @blueprint, 'dataset.commits')
    
    # both still compute
    # since we did not change the grain the results are the same
    expect(m.execute).to eq 6
    expect(report.execute.to_a).to eq [['jirka@gmail.com', 'petr@gmail.com', 'tomas@gmail.com'],
                                       [3.0, 2.0, 1.0]]
  end
end
