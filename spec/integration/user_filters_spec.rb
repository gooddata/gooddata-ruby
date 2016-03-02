# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "User filters implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    @project = @client.create_project_from_blueprint(blueprint, :token => ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)

    @label = GoodData::Attribute.find_first_by_title('Dev', client: @client, project: @project).label_by_name('email')

    commits_data = [
      ["lines_changed","committed_on","dev_id","repo_id"],
      [1,"01/01/2014",1,1],
      [3,"01/02/2014",2,2],
      [5,"05/02/2014",3,1],
      [6,"05/02/2014",1,2]]
    @project.upload(commits_data, blueprint, 'dataset.commits')

    devs_data = [
      ["dev_id", "email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    @project.upload(devs_data, blueprint, 'dataset.devs')

    repos_data = [
      ["repo_id", "repo_name"],
      [1, "goodot"],
      [2, "bam"],
      [3, "infra"]]
    @project.upload(repos_data, blueprint, 'dataset.repos')
  end

  after(:all) do
    @project.delete if @project
  end

  after(:each) do
    @project.data_permissions.pmap &:delete
  end

  it "should create a mandatory user filter" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com', 'jirka@gooddata.com']]

    metric = @project.create_metric("SELECT SUM(#\"Lines Changed\")", :title => 'x')
    # [jirka@gooddata.com | petr@gooddata.com | tomas@gooddata.com]
    # [5.0                | 3.0               | 1.0               ]

    metric.execute.should == 15
    @project.add_data_permissions(filters)
    metric.execute.should == 12
    r = @project.compute_report(left: [metric], top: [@label.attribute])
    r.include_column?(['tomas@gooddata.com', 7]).should == true
    r.include_column?(['jirka@gooddata.com', 5]).should == true
    r.include_column?(['petr@gooddata.com', 3]).should == false
  end

  it "should return errors when asked to set a user not in project. Some filters are set up though." do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, "tomas@gooddata.com"],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    results = @project.add_data_permissions(filters)
    expect(results[:results].any? { |r| r[:status] == :failed }).to be_truthy
    expect(@project.data_permissions.count).to eq 2
  end

  it "should pass and set users that are in the projects" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(filters)
    expect(@project.data_permissions.count).to eq 1
  end

  it "should pass and set only users that are in the projects if asked" do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, 'tomas@gooddata.com'],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com']
    ]
    # note that filters will be set up even for nonexistent users but they will not be assigned
    @project.add_data_permissions(filters, users_must_exist: false)
    expect(@project.data_permissions.select(&:related_uri).count).to eq 1
    expect(@project.data_permissions.select(&:related_uri).first.pretty_expression).to eq "[Dev] IN ([tomas@gooddata.com])"
  end

  it "should fail when asked to set a value not in the project" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'tomas@gooddata.com']]
    expect do
      @project.add_data_permissions(filters)
    end.to raise_error
    begin
      @project.add_data_permissions(filters)
    rescue GoodData::FilterMaqlizationError => e
      expect(e.errors.count).to eq 1
    end
    expect(@project.data_permissions.count).to eq 0
  end

  it 'should fail but return all values if specified' do
    domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    u = domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'tomas@gooddata.com'],
      [u.login, @label.uri, '%^&*( other nonexistent value', 'jirka@gooddata.com']
    ]
    expect do
      @project.add_data_permissions(filters, fail_early: false)
    end.to raise_error
    begin
      @project.add_data_permissions(filters, fail_early: false)
    rescue GoodData::FilterMaqlizationError => e
      expect(e.errors.count).to eq 2
    end
    expect(@project.data_permissions.count).to eq 0
  end

  it "should add a filter with nonexistent values when asked" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'jirka@gooddata.com']]
    @project.add_data_permissions(filters, ignore_missing_values: true)

    expect(@project.data_permissions.pmap {|m| m.pretty_expression}).to eq ["[Dev] IN ([jirka@gooddata.com])"]
    expect(@project.data_permissions.count).to eq 1
  end

  it "should be able to add mandatory filter to a user not in the project if domain is provided" do
    domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
    u = domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }

    filters = [[u.login, @label.uri, "tomas@gooddata.com"]]
    results = @project.add_data_permissions(filters)
    filters = @project.data_permissions
    expect(filters.first.related.login).to eq u.login
    expect(filters.select(&:related_uri).count).to eq 1
    expect(filters.first.pretty_expression).to eq "[Dev] IN ([tomas@gooddata.com])"
  end

  it "should be able to print data permissions in a human readable form" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]]
    @project.add_data_permissions(filters)
    perms = @project.data_permissions
    pretty = perms.pmap {|f| [f.related.login, f.pretty_expression]}
    expect(perms.first.related).to eq @client.user
    expect(pretty).to eq [[ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"]]
  end

  it "sets up mandatory users based on the state given as an end state by default." do
    # first let's prepare some user filters
    user_with_already_set_up_filter = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)

    filters = [
      [user_with_already_set_up_filter.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(filters)
    expect(@project.data_permissions.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"]]

    # Now let's add user filter to a different user. If we do not explicitely state that
    # user_with_already_set_up_filter should keep his filter it will be removed
    another_user = @domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    @project.add_user(another_user, 'Admin', domain: @domain)
    new_filters = [
      [another_user.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(new_filters)
    expect(@project.data_permissions.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[another_user.login, "[Dev] IN ([tomas@gooddata.com])"]]
  end

  it "should set up false if all values are nonexistent" do
    metric = GoodData::Fact.find_first_by_title('Lines Changed', client: @client, project: @project).create_metric

    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "NONEXISTENT1", "NONEXISTENT2", "NONEXISTENT3"]]
    @project.add_data_permissions(filters, ignore_missing_values: true)
    expect(metric.execute).to eq 15
    @project.add_data_permissions(filters, ignore_missing_values: true, restrict_if_missing_all_values: true)
    expect(metric.execute).to eq nil
  end

  it "you can switch the updates. Whatever is not mentioned will not be touched" do
    # first let's prepare some user filters
    user_with_already_set_up_filter = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)

    filters = [
      [user_with_already_set_up_filter.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(filters)
    expect(@project.data_permissions.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"]]

    # Now let's add user filter to a different user. If we do not explicitely state that
    # user_with_already_set_up_filter should keep his filter it will be removed
    another_user = @domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    @project.add_user(another_user, 'Admin', domain: @domain)
    new_filters = [
      [another_user.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_data_permissions(new_filters, do_not_touch_filters_that_are_not_mentioned: true)
    expect(@project.data_permissions.map {|f| [f.related.login, f.pretty_expression] })
      .to include([ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"], [another_user.login, "[Dev] IN ([tomas@gooddata.com])"])
  end

  it "should be able to update the filter value" do
    skip('We cannot swap filters yet')
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com", "jirka@gooddata.com"]]
    @project.add_data_permissions(filters)
    perm = @project.data_permissions.first
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]]
    @project.add_data_permissions(filters)
    expect(perm.reload!.pretty_expression).to eq '[Dev] IN ([tomas@gooddata.com, jirka@gooddata.com])'
  end

  it 'should not create any superfluous filters if things go well' do
    # first create some filters. This will error out and some filters will stay there
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, "tomas@gooddata.com"],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    results = @project.add_data_permissions(filters)

    # now let's do a correct run
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    results = @project.add_data_permissions(filters)
    expect(results[:results].all? { |r| r[:status] == :successful }).to be_truthy
    expect(results[:results].select {|r| r[:type] == :create }.count).to eq 1
    expect(@project.data_permissions.count).to eq 1
  end

  it "should create a mandatory user filter with double filters" do

    repo_label = @project.labels('some_attr_label_id')
    metric = @project.create_metric("SELECT SUM(#\"Lines Changed\")")

    # we want to compute stuff on different user than we are setting it on
    u = @domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    password = 'abcd1234'
    u.json['accountSetting']['password'] = password
    @domain.update_user(u)
    @project.add_user(u, 'admin')

    computation_client = GoodData.connect(u.login, password, verify_ssl: false)
    computation_project = computation_client.projects(@project.pid)

    # verify we are set up
    r = computation_project.compute_report(left: [metric, 'some_attr_label_id'], top: [@label])
    expect(r.column(4)).to eq ["tomas@gooddata.com", 6, 1]

    # lets restrict tomas to goodot only
    filters = [[u.login, @label.uri, 'tomas@gooddata.com'],
               [u.login, repo_label.uri, 'goodot']]
    results = @project.add_data_permissions(filters)
    expect(@project.data_permissions.pmap {|f| [f.related.login, f.pretty_expression]}).to eq [
      [u.login, "[Dev] IN ([tomas@gooddata.com])"],
      [u.login, "[Repository Name] IN ([goodot])"]]

    r = computation_project.compute_report(left: [metric, 'some_attr_label_id'], top: [@label])
    expect(r.column(2)).to eq ["tomas@gooddata.com", 1]

    # Now lets change repo to bam
    filters = [[u.login, @label.uri, 'tomas@gooddata.com'],
               [u.login, repo_label.uri, 'bam']]
    results = @project.add_data_permissions(filters)

    expect(@project.data_permissions.pmap {|f| [f.related.login, f.pretty_expression]}).to eq [
      [u.login, "[Dev] IN ([tomas@gooddata.com])"],
      [u.login, "[Repository Name] IN ([bam])"]]

    r = computation_project.compute_report(left: [metric, 'some_attr_label_id'], top: [@label])
    expect(r.column(2)).to eq ["tomas@gooddata.com", 6]

    # let's remove the repo restriction
    filters = [[u.login, @label.uri, 'tomas@gooddata.com']]
    results = @project.add_data_permissions(filters)

    r = computation_project.compute_report(left: [metric, 'some_attr_label_id'], top: [@label])
    expect(r.column(2)).to eq ["tomas@gooddata.com", 6, 1]
  end
end
