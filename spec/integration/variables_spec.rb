# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Variables implementation", :constraint => 'slow' do
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
      [5,"05/02/2014",3,1]]
    @project.upload(commits_data, blueprint, 'dataset.commits')
    
    devs_data = [
      ["dev_id", "email"],
      [1, "tomas@gooddata.com"],
      [2, "petr@gooddata.com"],
      [3, "jirka@gooddata.com"]]
    @project.upload(devs_data, blueprint, 'dataset.devs')
    
    @variable = @project.create_variable(title: 'uaaa', attribute: @label.attribute).save

  end

  after(:all) do
    @project.delete if @project
  end

  after(:each) do
    @variable.user_values.select {|x| x.level == :user}.pmap &:delete
  end

  it "should create a variable filter" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com', 'jirka@gooddata.com']]

    metric = @project.create_metric("SELECT SUM(#\"Lines Changed\")", :title => 'x')

    # [jirka@gooddata.com | petr@gooddata.com | tomas@gooddata.com]
    # [5.0                | 3.0               | 1.0               ]
    @project.add_variable_permissions(filters, @variable)
    r = @project.compute_report(left: [metric], top: [@label.attribute], filters: [@variable])
    r.include_column?(['tomas@gooddata.com', 1]).should == true
    r.include_column?(['jirka@gooddata.com', 5]).should == true
    r.include_column?(['petr@gooddata.com', 3]).should == false

    r = @project.compute_report(left: [metric], top: [@label.attribute])
    r.include_column?(['tomas@gooddata.com', 1]).should == true
    r.include_column?(['jirka@gooddata.com', 5]).should == true
    r.include_column?(['petr@gooddata.com', 3]).should == true
  end

  it "should fail when asked to set a user not in project. No filters should be set up." do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, "tomas@gooddata.com"],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    expect do
      @project.add_variable_permissions(filters, @variable)
    end.to raise_error
    expect(@variable.user_values.count).to eq 0
  end

  it "should pass and set users that are in the projects" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_variable_permissions(filters, @variable)
    expect(@variable.user_values.count).to eq 1
  end
  
  it "should pass and set only users that are in the projects if asked" do
    filters = [
      ['nonexistent_user@gooddata.com', @label.uri, 'tomas@gooddata.com'],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com']
    ]
    @project.add_variable_permissions(filters, @variable, users_must_exist: false)
    expect(@variable.user_values.count).to eq 1
  end
  
  it "should fail when asked to set a value not in the proejct" do
    filters = [
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'tomas@gooddata.com'],
      [ConnectionHelper::DEFAULT_USERNAME, @label.uri, 'tomas@gooddata.com']]
    expect do
      @project.add_variable_permissions(filters, @variable)
    end.to raise_error
    expect(@variable.user_values.count).to eq 0
  end
  
  it "should add a filter with nonexistent values when asked" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, '%^&*( nonexistent value', 'jirka@gooddata.com']]
    @project.add_variable_permissions(filters, @variable, ignore_missing_values: true)
  
    expect(@variable.user_values.pmap {|m| m.pretty_expression}).to eq ["[Dev] IN ([jirka@gooddata.com])"]
    expect(@variable.user_values.count).to eq 1
  end

  it "should be able to print data permissions in a human readable form" do
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]]
    @project.add_variable_permissions(filters, @variable)
    perms = @variable.user_values
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
    @project.add_variable_permissions(filters, @variable)
    expect(@variable.user_values.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"]]

    # Now let's add user filter to a different user. If we do not explicitely state that
    # user_with_already_set_up_filter should keep his filter it will be removed
    another_user = @domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    @project.add_user(another_user, 'Admin', domain: @domain)
    new_filters = [
      [another_user.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_variable_permissions(new_filters, @variable)
    expect(@variable.user_values.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[another_user.login, "[Dev] IN ([tomas@gooddata.com])"]]
  end

  it "should set up false if all values are nonexistent" do
    metric = GoodData::Fact.find_first_by_title('Lines Changed', client: @client, project: @project).create_metric
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "NONEXISTENT1", "NONEXISTENT2", "NONEXISTENT3"]]
    @project.add_variable_permissions(filters, @variable, ignore_missing_values: true)
    # expect(metric.execute).to eq 9
    expect(@variable.user_values.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[ConnectionHelper::DEFAULT_USERNAME, "TRUE"]]

    @project.add_variable_permissions(filters, @variable, ignore_missing_values: true, restrict_if_missing_all_values: true)
    # expect(metric.execute).to eq nil
    expect(@variable.user_values.count).to eq 0
  end

  it "you can switch the updates. Whatever is not mentioned will not be touched" do
    # first let's prepare some user filters
    user_with_already_set_up_filter = @project.get_user(ConnectionHelper::DEFAULT_USERNAME)

    filters = [
      [user_with_already_set_up_filter.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_variable_permissions(filters, @variable)
    expect(@variable.user_values.map {|f| [f.related.login, f.pretty_expression] })
      .to eq [[ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"]]
    # Now let's add user filter to a different user. If we do not explicitely state that
    # user_with_already_set_up_filter should keep his filter it will be removed
    another_user = @domain.users.find { |u| u.login != ConnectionHelper::DEFAULT_USERNAME }
    @project.add_user(another_user, 'Admin', domain: @domain)
    new_filters = [
      [another_user.login, @label.uri, "tomas@gooddata.com"]
    ]
    @project.add_variable_permissions(new_filters, @variable, do_not_touch_filters_that_are_not_mentioned: true)
    expect(@variable.user_values.map {|f| [f.related.login, f.pretty_expression] })
      .to include([ConnectionHelper::DEFAULT_USERNAME, "[Dev] IN ([tomas@gooddata.com])"],
                  [another_user.login, "[Dev] IN ([tomas@gooddata.com])"])
  end

  it "should be able to update the filter value in place" do
    skip('We cannot swap filters yet')
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com", "jirka@gooddata.com"]]
    @project.add_variable_permissions(filters, @variable)
    perm = @variable.user_values.first
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, "tomas@gooddata.com"]]
    @project.add_variable_permissions(filters, @variable)
    expect(perm.reload!.pretty_expression).to eq '[Dev] IN ([tomas@gooddata.com, jirka@gooddata.com])'
  end
end
