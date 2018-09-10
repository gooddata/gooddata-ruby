shared_context 'a user action in sync_domain_client_workspaces mode' do
  let(:data_product_id) { "data_product_#{@suffix}" }
  let(:segment_id) { "testing-segment-for-filter-#{@suffix}" }
  before do
    @test_context[:sync_mode] = 'sync_domain_client_workspaces'
    @data_product = @domain.create_data_product(id: data_product_id)
    @master_project = @rest_client.create_project(title: "Test MASTER project 3 for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
    @segment = @data_product.create_segment(segment_id: segment_id, master_project: @master_project)
    @segment.create_client(id: 'testingclient', project: @project.uri)
    @master_project_not_in_filter = @rest_client.create_project(title: "Test MASTER project 4 for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
    @segment_not_in_filter = @data_product.create_segment(segment_id: "testing-segment-3-not-in-filter-#{@suffix}", master_project: @master_project_not_in_filter)
    project_helper = Support::ProjectHelper.create(@opts)
    project_helper.create_ldm
    project_helper.load_data
    @project_not_in_filter = project_helper.project
    @segment_not_in_filter.create_client(id: 'testingclient-not-in-filter', project: @project_not_in_filter.uri)
    @test_context[:data_product] = data_product_id
    @test_context[:segments_filter] = [segment_id]
    config_path = ConfigurationHelper.create_interpolated_tempfile(
        @template_path,
        @test_context
    )

    $SCRIPT_PARAMS = JSON.parse(File.read(config_path))
  end

  after do
    @data_product.delete(force: true) if @data_product
    @master_project.delete if @master_project
    @master_project_not_in_filter.delete if @master_project_not_in_filter
  end
end
