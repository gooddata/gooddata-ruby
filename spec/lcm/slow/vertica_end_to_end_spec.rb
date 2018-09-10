require_relative '../integration/shared_contexts_for_lcm'
require_relative '../integration/support/s3_helper'
require_relative '../integration/support/lcm_helper'

shared_examples 'a HLL fact synchronizer' do
  it 'migrates hll fact' do
    target_projects.each do |project|
      hll_fact = project.facts.find { |f| f.identifier == 'fact.cars.milage' }
      expect(hll_fact).not_to be_nil
      fact_type = hll_fact.data['content']['type']
      expect(fact_type).to eq('hll')
    end
  end
end

describe 'the whole life-cycle' do
  before(:all) do
    @suffix = ConfigurationHelper.suffix
    @prod_rest_client = LcmConnectionHelper.production_server_connection
    @domain = @prod_rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @ads = ConfigurationHelper.create_development_datawarehouse(
      client: @prod_rest_client,
      title: 'ADS',
      auth_token: LcmConnectionHelper.environment[:vertica_prod_token]
    )
    @ads_client = GoodData::Datawarehouse.new(
        LcmConnectionHelper.environment[:username],
        LcmConnectionHelper.environment[:password],
        nil,
        jdbc_url: @ads.data['connectionUrl']
    )
    @opts = {
      client: @prod_rest_client,
      title: "Project #{@suffix}",
      auth_token: LcmConnectionHelper.environment[:vertica_prod_token],
      environment: 'TESTING',
      driver: 'vertica'
    }
    project_helper = Support::ProjectHelper.create(@opts)
    model_path = File.join(File.dirname(__FILE__), 'data/hll_model.json')
    project_helper.create_ldm(model_path)
    data_path = File.join(File.dirname(__FILE__), 'data/cars.csv')
    project_helper.load_data(data_path, 'dataset.cars')
    premium_segment = "CAR_DEMO_PREMIUM_#{@suffix}"
    premium_master_name = "Car Demo Master (Premium) #{@suffix}" + ' ##{version}'
    @release_table_name = "LCM_RELEASE_#{@suffix}"
    LcmHelper.create_release_table(@release_table_name, @ads_client)
    @workspace_table_name = "LCM_WORKSPACE_#{@suffix}"
    LcmHelper.create_workspace_table(@workspace_table_name, @ads_client)
    @project = project_helper.project
    ws = {
        client_id: "CAR_DEMO_#{@suffix}",
        segment_id: premium_segment,
        title: "Car Demo Workspace #{@suffix}"
    }
    query = "INSERT INTO \"#{@workspace_table_name}\" VALUES('#{ws[:client_id]}', '#{ws[:segment_id]}', 1, '#{ws[:title]}');"
    @ads_client.execute(query)
    @test_context = {
      project_id: @project.pid,
      config: LcmConnectionHelper.environment,
      premium_segment: premium_segment,
      premium_master_name: premium_master_name,
      release_table_name: @release_table_name,
      workspace_table_name: @workspace_table_name,
      jdbc_url: @ads.data['connectionUrl'],
      development_pid: @project.obj_id
    }
  end

  after(:each) do
    $SCRIPT_PARAMS = nil
  end

  after(:all) do
    projects_to_delete = [@project] + $master_projects + $client_projects

    projects_to_delete.each do |project|
      begin
        GoodData.logger.info("Deleting project \"#{project.title}\" with ID #{project.pid}")
        project.delete unless project.deleted?
      rescue StandardError => e
        GoodData.logger.warn("Failed to delete project #{project.title}. #{e}")
        GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
      end
    end

    begin
      GoodData.logger.info("Deleting ADS #{@ads.obj_id}")
      @ads.delete
    rescue StandardError => e
      GoodData.logger.warn("Failed to delete development ADS. #{e}")
      GoodData.logger.warn("Backtrace:\n#{e.backtrace.join("\n")}")
    end
  end

  describe '1 - Initial Release' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/release_brick.json.erb',
        __FILE__
      )
    end

    include_context 'release brick'
    it_behaves_like 'a HLL fact synchronizer' do
      let(:target_projects) { $master_projects }
    end
  end

  describe '2 - Initial Provisioning' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/provisioning_brick.json.erb',
        __FILE__
      )
    end

    include_context 'provisioning brick'
    it_behaves_like 'a HLL fact synchronizer' do
      let(:target_projects) { $client_projects }
    end
  end

  describe '3 - Initial Rollout' do
    before(:all) do
      @config_template_path = File.expand_path(
        '../params/rollout_brick.json.erb',
        __FILE__
      )
    end

    include_context 'rollout brick'
    it_behaves_like 'a HLL fact synchronizer' do
      let(:target_projects) { $client_projects }
    end
  end
end
