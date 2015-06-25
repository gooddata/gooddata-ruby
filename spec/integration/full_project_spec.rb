require 'gooddata'

describe "Full project implementation", :constraint => 'slow' do
  before(:all) do
    @spec = JSON.parse(File.read("./spec/data/blueprints/test_project_model_spec.json"), :symbolize_names => true)
    @invalid_spec = JSON.parse(File.read("./spec/data/blueprints/invalid_blueprint.json"), :symbolize_names => true)
    @client = ConnectionHelper::create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
    @invalid_blueprint = GoodData::Model::ProjectBlueprint.new(@invalid_spec)

    @project = @client.create_project_from_blueprint(@blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
  end

  after(:all) do
    @project.delete unless @project.nil?

    @client.disconnect
  end

  it "should not build an invalid model" do
    expect {
      @client.create_project_from_blueprint(@invalid_spec, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    }.to raise_error(GoodData::ValidationError)
  end

  it "should do nothing if the project is updated with the same blueprint" do
    results = GoodData::Model::ProjectCreator.migrate_datasets(@spec, project: @project, client: @client, dry_run: true)
    expect(results).to be_nil
  end

  it 'should try to rename a dataset back' do
    dataset = @project.datasets('dataset.repos')
    dataset.title = "Some title"
    dataset.save

    # Now the update of project using the original blueprint should offer update of the title. Nothing else.
    results = GoodData::Model::ProjectCreator.migrate_datasets(@blueprint, project: @project, client: @client, dry_run: true)
    results = GoodData::Model::ProjectCreator.migrate_datasets(@spec, project: @project, client: @client, dry_run: true)
    expect(results['updateScript']['maqlDdl']).to eq "ALTER DATASET {dataset.repos} VISUAL(TITLE \"Repositories\", DESCRIPTION \"\");\n"

    # Update using a freshly gained blueprint should offer no changes.
    new_blueprint = @project.blueprint
    results = GoodData::Model::ProjectCreator.migrate_datasets(new_blueprint, project: @project, client: @client, dry_run: true)
    expect(results).to be_nil

    # When we change the model using the original blueprint. Basically change the title back.
    results = @project.update_from_blueprint(@spec)
    # It should offer no changes using the original blueprint
    results = GoodData::Model::ProjectCreator.migrate_datasets(@spec, project: @project, client: @client, dry_run: true)
    expect(results).to be_nil
  end

  it "should contain datasets" do
    bp = @project.blueprint
    expect(bp.datasets.count).to eq 3
    expect(bp.datasets(:all, :include_date_dimensions => true).count).to eq 4
  end

  it "should contain metadata datasets" do
    expect(@project.datasets.count).to eq 4
    expect(@project.datasets.select(&:date_dimension?).count).to eq 1
  end

  it "should be able to rename a project" do
    former_title = @project.title
    a_title = (0...8).map { (65 + rand(26)).chr }.join
    @project.title = a_title
    @project.save
    expect(@project.title).to eq a_title
    @project.title = former_title
    @project.save
  end

  it "should be able to validate a project" do
    @project.validate
  end

  it "should compute an empty metric" do
    f = @project.fact_by_title('Lines Changed')
    metric = @project.create_metric("SELECT SUM(#\"#{f.title}\")")
    expect(metric.execute).to be_nil
  end

  it "should compute an empty report def" do
    @project.delete_all_data(force: true)
    f = @project.fact_by_title('Lines Changed')
    metric = @project.create_metric("SELECT SUM(#\"#{f.title}\")")
    res = @project.compute_report(:left => [metric])
    expect(res).to be_empty
  end

  it "should load the data" do
    GoodData.with_project(@project) do |p|
      # blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      commits_data = [
        ["lines_changed","committed_on","dev_id","repo_id"],
        [1,"01/01/2014",1,1],
        [3,"01/02/2014",2,2],
        [5,"05/02/2014",3,1]]
      @project.upload(commits_data, @blueprint, 'dataset.commits')

      devs_data = [
        ["dev_id", "email"],
        [1, "tomas@gooddata.com"],
        [2, "petr@gooddata.com"],
        [3, "jirka@gooddata.com"]]
      @project.upload(devs_data, @blueprint, 'dataset.devs')
    end
  end

  it "it silently ignores extra columns" do
    GoodData.with_project(@project) do |p|
      blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
      commits_data = [
        ["lines_changed","committed_on","dev_id","repo_id", "extra_column"],
        [1,"01/01/2014",1,1,"something"],
        [3,"01/02/2014",2,2,"something"],
        [5,"05/02/2014",3,1,"something else"]
      ]
      @project.upload(commits_data, blueprint, 'dataset.commits')
    end
  end

  context "it should give you a reasonable error message" do
    it "if you omit a column" do
      GoodData.with_project(@project) do |p|
        blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
        commits_data = [
          ["lines_changed","committed_on","dev_id"],
          [1,"01/01/2014",1],
          [3,"01/02/2014",2],
          [5,"05/02/2014",3]
        ]
        expect {@project.upload(commits_data, blueprint, 'dataset.commits')}.to raise_error(/repo_id/)
      end
    end
    it "if you give it a malformed CSV" do
      GoodData.with_project(@project) do |p|
        blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
        # 4 cols in header but not in the data
        commits_data = [
          ["lines_changed","committed_on","dev_id","repo_id"],
          [1,"01/01/2014",1],
          [3,"01/02/2014",2],
          [5,"05/02/2014",3]
        ]
        expect {@project.upload(commits_data, blueprint, 'dataset.commits')}.to raise_error(/Number of columns/)
      end
    end
    it "if you give it wrong date format" do
      GoodData.with_project(@project) do |p|
        blueprint = GoodData::Model::ProjectBlueprint.new(@spec)
        commits_data = [
          ["lines_changed","committed_on","dev_id","repo_id"],
          [1,"01/01/2014",1,1],
          [3,"45/50/2014",2,2],
          [5,"05/02/2014",3,1]
        ]
        expect {@project.upload(commits_data, blueprint, 'dataset.commits')}.to raise_error(%r{45/50/2014})
      end
    end
  end

  it "should compute a metric" do
    f = @project.fact_by_title('Lines Changed')
    metric = @project.create_metric("SELECT SUM(#\"#{f.title}\")")
    expect(metric.execute).to eq 9
  end

  it "should compute a count metric from dataset" do
    # works on anchor without label
    expect(@blueprint.datasets('dataset.commits').count(@project)).to eq 3

    # works on anchor with label
    expect(@blueprint.datasets('dataset.devs').count(@project)).to eq 3
  end

  it "should execute an anonymous metric twice and not fail" do
    f = @project.fact_by_title('Lines Changed')
    metric = @project.create_metric("SELECT SUM(#\"#{f.title}\")")
    expect(metric.execute).to eq 9
    # Since GD platform cannot execute inline specified metric the metric has to be saved
    # The code tries to resolve this as transparently as possible
    # Here we are testing that you can execute the metric twice. The first execution is on unsaved metric
    # We wanna make sure that when we are cleaning up we are not messing things up
    expect(metric.execute).to eq 9
  end

  it "should compute a report def" do
    f = @project.fact_by_title('Lines Changed')

    # TODO: Here we create metric which is not deleted and is used by another test - "should exercise the object relations and getting them in various ways"
    metric = @project.create_metric("SELECT SUM(#\"#{f.title}\")", :title => "My metric")
    metric.save
    result = @project.compute_report(:top => [metric], :left => ['label.devs.dev_id.email'])
    expect(result[1][1]).to eq 3
    expect(result.include_row?(["jirka@gooddata.com", 5])).to be true

    result2 = @project.compute_report(:top => [metric], :left => ['label.devs.dev_id.email'])
    expect(result2[1][1]).to eq 3
    expect(result2.include_row?(["jirka@gooddata.com", 5])).to eq true
    expect(result2).to eq result
  end

  it "should be able to lock reports and everything underneath" do
    m = @project.metrics.first
    r = @project.create_report(top: [m], title: 'xy')
    r.save
    expect(m.locked?).to eq false
    expect(r.locked?).to eq false
    r.lock_with_dependencies!
    expect(r.locked?).to eq true
    m.reload!
    expect(m.locked?).to eq true
    r.unlock_with_dependencies!
    expect(r.locked?).to eq false
    m.reload!
    expect(m.locked?).to eq false
    r.lock!
    expect(r.locked?).to eq true
    r.unlock!
    expect(r.locked?).to eq false
  end

  it "should be able to purge report from older revisions" do
    m = @project.metrics.first
    r = @project.create_report(top: [m], title: 'xy')
    expect(r.definitions.count).to eq 1

    rd = GoodData::ReportDefinition.create(:top => [m], :client => @client, :project => @project)
    rd.save
    r.add_definition(rd)
    r.save
    expect(r.definitions.count).to eq 2
  end

  it "should be able to clean colors from a chart report def" do
    f = @project.fact_by_title('Lines Changed')
    m = @project.create_metric("SELECT SUM(#\"#{f.title}\")", title: 'test metric').save
    r = @project.create_report(top: [m], title: 'xy')
    rd = r.latest_report_definition
    rd.content['chart'] = { 'styles' => { 'global' => { 'colorMapping' => 1 } } }

    expect(GoodData::Helpers.get_path(rd.content, %w(chart styles global))).to eq ({ 'colorMapping' => 1 })
    rd.reset_color_mapping!
    expect(GoodData::Helpers.get_path(rd.content, %w(chart styles global))).to eq ({ 'colorMapping' => [] })
    r.delete
    res = m.used_by
    res.each do |dependency|
      @client.delete dependency['link']
    end
    res = m.used_by
    expect(res.length).to eq 0
    m.delete
  end

  it "should be possible to get all metrics" do
    metrics1 = @project.metrics
    expect(metrics1.count).to be >= 0
  end

  it "should be possible to get all metrics with full objects" do
    metrics = @project.metrics(:all)
    expect(metrics.first.class).to be GoodData::Metric
  end

  it "should be able to get a metric by identifier" do
    metrics = @project.metrics
    metric = @project.metrics(metrics.first.identifier)
    expect(metric.identifier).to eq metrics.first.identifier
    expect(metrics.first).to eq metric
  end

  it "should be able to get a metric by uri" do
    metrics = @project.metrics
    metric = @project.metrics(metrics.first.uri)
    expect(metric.uri).to eq metrics.first.uri
    expect(metrics.first).to eq metric
  end

  it "should be able to get a metric by object id" do
    metrics = @project.metrics
    metric = @project.metrics(metrics.first.obj_id)
    expect(metric.obj_id).to eq metrics.first.obj_id
    expect(metrics.first).to eq metric
  end

  it "should exercise the object relations and getting them in various ways" do
    # Find a metric by name
    metric = @project.metric_by_title('My metric')
    the_same_metric = @project.metrics(metric)
    expect(metric).to eq the_same_metric

    # grab fact in several different ways
    fact1 = @project.fact_by_title('Lines Changed')
    fact2 = @project.facts(fact1.identifier)
    fact3 = @project.facts(fact2.obj_id)
    fact4 = @project.facts(fact3.uri)
    fact5 = @client.create(GoodData::Fact, fact4)

    # All should be the same
    expect(fact1).to eq fact2
    expect(fact1).to eq fact2
    expect(fact1).to eq fact3
    expect(fact1).to eq fact4
    expect(fact1).to eq fact5

    fact3.title = "Somewhat changed title"
    expect(fact1).not_to eq fact3

    metric.using(nil)
    res = metric.using('fact')
    expect(res.count).to eq 1

    fact1.used_by(nil)
    res = fact1.used_by('metric')
    expect(res.count).to eq 1

    res = metric.using?(fact1)
    expect(res).to be(true)

    res = fact1.using?(metric)
    expect(res).to be(false)

    res = metric.used_by?(fact1)
    expect(res).to be(false)

    res = fact1.used_by?(metric)
    expect(res).to be(true)
  end

  it "should try setting and getting by tags" do
    fact = @project.fact_by_title('Lines Changed')
    expect(fact.tags.empty?).to be_truthy

    fact.tags = "tag1,tag2,tag3"
    fact.save

    tagged_facts = GoodData::Fact.find_by_tag('tag3', :client => @client, :project => @project)
    expect(tagged_facts.count).to eq 1
  end

  it "should be able to interpolate metric based on" do
    res = @project.compute_metric "SELECT SUM(![fact.commits.lines_changed])"
    expect(res).to eq 9

    res = @project.compute_metric "SELECT SUM(![fact.commits.lines_changed])"
    expect(res).to eq 9

    res = @project.compute_metric "SELECT SUM(![fact.commits.lines_changed])"
    expect(res).to eq 9

    res = @project.compute_metric "SELECT SUM(![fact.commits.lines_changed])"
    expect(res).to eq 9

    fact = @project.fact_by_title('Lines Changed')
    expect(fact.fact?).to be true
    res = fact.create_metric(:type => :sum).execute
    expect(res).to eq 9
  end

  it "should load the data" do
    devs_data = [
      ["dev_id", "email"],
      [4, "josh@gooddata.com"]]
    @project.upload(devs_data, @blueprint, 'dataset.devs', mode: 'INCREMENTAL')
  end

  it "should have more users"  do
    attribute = @project.attributes('attr.devs.dev_id')
    expect(attribute.attribute?).to be true
    expect(attribute.create_metric.execute).to eq 4
  end

  it "should tell you whether metric contains a certain attribute" do
    attribute = @project.attributes('attr.devs.dev_id')
    repo_attribute = @project.attributes('attr.repos.repo_id')
    metric = attribute.create_metric(:title => "My test metric")
    metric.save
    expect(metric.execute).to eq 4

    expect(metric.contain?(attribute)).to be true
    expect(metric.contain?(repo_attribute)).to be false

    metric.replace(attribute, repo_attribute)
    metric.save
    expect(metric.execute).not_to eq 4

    l = attribute.primary_label
    value = l.values.first[:value]
    expect(l.find_element_value(l.find_value_uri(value))).to eq value
    expect(l.value?(value)).to eq true
    expect(l.value?("DEFINITELY NON EXISTENT VALUE HOPEFULLY")).to eq false
  end

  it "should be able to compute count of different datasets" do
    attribute = @project.attributes('attr.devs.dev_id')
    dataset_attribute = @project.attributes('attr.commits.factsof')
    expect(attribute.create_metric(:attribute => dataset_attribute).execute).to eq 3
  end

  it "should be able to tell you if a value is contained in a metric" do
    attribute = @project.attributes('attr.devs.dev_id')
    label = attribute.primary_label
    value = label.values.first
    fact = @project.facts('fact.commits.lines_changed')
    metric = @project.create_metric("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]")
    expect(metric.contain_value?(label, value[:value])).to be true
  end

  it "should be able to replace the values in a metric" do
    attribute = @project.attributes('attr.devs.dev_id')
    label = attribute.primary_label
    value = label.values.first
    different_value = label.values.drop(1).first
    fact = @project.facts('fact.commits.lines_changed')
    metric = @project.create_metric("SELECT SUM([#{fact.uri}]) WHERE [#{attribute.uri}] = [#{value[:uri]}]")
    metric.replace_value(label, value[:value], different_value[:value])
    expect(metric.contain_value?(label, value[:value])).to be false
    expect(metric.pretty_expression).to eq "SELECT SUM([Lines Changed]) WHERE [Dev] = [josh@gooddata.com]"
  end

  it "should be able to lookup the attributes by regexp and return a collection" do
    attrs = @project.attributes_by_title(/Date/i)
    expect(attrs.count).to eq 1
  end

  it "should be able to give you values of the label as an array of hashes" do
    attribute = @project.attributes('attr.devs.dev_id')
    label = attribute.primary_label
    expect(label.values.map { |v| v[:value] }).to eq [
      'jirka@gooddata.com',
      'josh@gooddata.com',
      'petr@gooddata.com',
      'tomas@gooddata.com'
    ]
  end

  it "should be able to give you values for" do
    attribute = @project.attributes('attr.devs.dev_id')
    expect(attribute.values_for(2)).to eq ["tomas@gooddata.com", "1"]
  end

  it "should be able to find specific element and give you the primary label value" do
    attribute = @project.attributes('attr.devs.dev_id')
    expect(@project.find_attribute_element_value("#{attribute.uri}/elements?id=2")).to eq 'tomas@gooddata.com'
  end

  it "should be able to give you label by name" do
    attribute = @project.attributes('attr.devs.dev_id')
    label = attribute.label_by_name('Id')
    expect(label.label?).to eq true
    expect(label.title).to eq 'Id'
    expect(label.identifier).to eq 'label.devs.dev_id.id'
    expect(label.attribute_uri).to eq attribute.uri
    expect(label.attribute).to eq attribute
  end

  it "should be able to return values of the attribute for inspection" do
    attribute = @project.attributes('attr.devs.dev_id')
    vals = attribute.values
    expect(vals.count).to eq 4
    expect(vals.first.count).to eq 2
    expect(vals.first.first[:value]).to eq "jirka@gooddata.com"
  end

  it "should be able to save_as a metric" do
    m = @project.metric_by_title("My test metric")
    cloned = m.save_as
    m_cloned = @project.metric_by_title("Clone of My test metric")
    expect(m_cloned).to eq cloned
    expect(m_cloned.execute).to eq cloned.execute
  end

  it "should be able to clone a project" do
    title = 'My new clone proejct'
    cloned_project = @project.clone(title: title, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)
    expect(cloned_project.title).to eq title
    expect(cloned_project.facts.first.create_metric.execute).to eq 9
    cloned_project.delete
  end

  it "should be able to clone a project without data" do
    title = 'My new clone project'
    cloned_project = @project.clone(title: title, auth_token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT, data: false)
    expect(cloned_project.title).to eq title
    expect(cloned_project.facts.first.create_metric.execute).to eq nil
    cloned_project.delete
  end

  it "should be able to export report" do
    m = @project.metrics.first
    r = @project.create_report(top: [m], title: 'Report to export')
    r.save
    r.export(:csv)
    r.export(:pdf)
    r.delete
  end

  it "should be able to delete report along with its definitions" do
    m = @project.metrics.first
    r = @project.create_report(top: [m], title: 'Report to delete')
    r.save
    def_uris = r.definition_uris
    r.delete
    expect { def_uris.each {|uri| @client.get(uri)} }.to raise_error(RestClient::ResourceNotFound)
  end

  it 'should be apossible to delete data from a dataset' do
    dataset = @project.datasets('dataset.devs')
    expect(dataset.attributes.first.create_metric.execute).to be > 0
    dataset.delete_data
    expect(dataset.attributes.first.create_metric.execute).to be_nil
  end
end
