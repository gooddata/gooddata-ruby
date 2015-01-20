require 'gooddata'

describe "Variables implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/m_n_model/blueprint.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    @project = @client.create_project_from_blueprint(@spec, :auth_token => ConnectionHelper::GD_PROJECT_TOKEN)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)

    @label = GoodData::Attribute.find_first_by_title('Perm User', client: @client, project: @project).label_by_name('email')

    @blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    commits_data = [
      ['commit_id', 'lines_changed', 'user_id'],
      [1, 1, 1],
      [2, 3, 2],
      [3, 5, 3]]
    GoodData::Model.upload_data(commits_data, @blueprint, 'commits', :client => @client, :project => @project)
    # blueprint.find_dataset('commits').upload(commits_data)

    devs_data = [
      ["user_id", "email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    GoodData::Model.upload_data(devs_data, @blueprint, 'users', :client => @client, :project => @project)

    devs_data = [
      ["perm_user_id", "email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    GoodData::Model.upload_data(devs_data, @blueprint, 'permission_users', :client => @client, :project => @project)
    # blueprint.find_dataset('devs').upload(devs_data)

    devs_data = [
      ['visibility_id', 'perm_user_id', 'commit_id'],
      [1, 1, 1],
      # [2, 1, 2],
      [3, 1, 3]]
    GoodData::Model.upload_data(devs_data, @blueprint, 'visibility', :client => @client, :project => @project)

    @variable = @project.create_variable(title: 'uaaa', attribute: @label.attribute).save

    @attr1 = GoodData::Attribute.find_first_by_title('Visibility', client: @client, project: @project)
    @attr2 = GoodData::Attribute.find_first_by_title('Commit', client: @client, project: @project)

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
    metric = @project.create_metric("SELECT SUM(#\"Lines Changed\")", :title => 'x')
    expect(metric.execute).to eq 9
    @project.add_data_permissions(@filters)
    expect(metric.execute).to eq 6

    r = @project.compute_report(left: [metric], top: @project.attributes('attr.users.user_id'))
    expect(r.include_column?(['tomas@gooddata.com', 1])).to eq true
    expect(r.include_column?(['jirka@gooddata.com', 5])).to eq true
    expect(r.include_column?(['petr@gooddata.com', 3])).to eq false

    devs_data = [['visibility_id', 'perm_user_id', 'commit_id'], [1, 1, 1]]
    GoodData::Model.upload_data(devs_data, @blueprint, 'visibility', :client => @client, :project => @project)

    expect(metric.execute).to eq 1
    r = @project.compute_report(left: [metric], top: @project.attributes('attr.users.user_id'))
    expect(r.include_column?(['tomas@gooddata.com', 1])).to eq true
    expect(r.include_column?(['jirka@gooddata.com', 5])).to eq false
    expect(r.include_column?(['petr@gooddata.com', 3])).to eq false
  end
end
