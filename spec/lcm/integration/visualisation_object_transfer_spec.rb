require_relative 'support/connection_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'

require_relative 'support/project_helper'
require_relative 'shared_examples_for_synchronization_bricks'

require 'active_support'
require 'active_support/core_ext'

def prepare_visualisation_object(rest_client, project)
  visualization_classes = GoodData::MdObject.query('visualizationClass', GoodData::MdObject, client: rest_client, project: project)
  visualization_class = visualization_classes.first
  attribute = project.attributes.first
  visualization_data = {
   visualizationObject: {
     content: {
       visualizationClass: {
         uri: visualization_class.uri
       },
       buckets: [{
         localIdentifier: "measure",
         items: [{
           measure: {
             localIdentifier: "M1",
             title: "Count of Account",
             format: "#,##0.00",
             definition: {
               measureDefinition: {
                 item: {
                   uri: attribute.uri
                 },
                 aggregation: "count"
               }
             }
           }
         }]
       }]
     },
     meta: {}
   }
  }
  v = GoodData::MdObject.new(visualization_data.deep_stringify_keys)
  v.title = 'Foo'
  v.project =  project
  v.client  = rest_client
  v.save
end

describe 'release brick' do
  before(:all) do
    @config = {
      verify_ssl: false,
      environment: 'TESTING',
      master_prefix: 'Insurance Demo Master'
    }
    @suffix = ConfigurationHelper.suffix
    @release_table_name = "LCM_RELEASE_#{@suffix}"
    @config.merge!(LcmConnectionHelper.environment)

    @rest_client = LcmConnectionHelper.development_server_connection

    @ads = ConfigurationHelper.create_development_datawarehouse(client: @rest_client,
                                            title: 'Development ADS',
                                            auth_token: @config[:dev_token])

    basic_segment = "INSURANCE_DEMO_BASIC_#{@suffix}"
    basic_master_name = "Insurance Demo Master (Basic) #{@suffix}" + ' ##{version}'

    data_product_id = "DATA_PRODUCT_#{@suffix}"
    domain = @rest_client.domain(@config[:dev_organization])
    domain.data_products(:all).each { |d| d.delete(force: true) }

    project_helper = ConfigurationHelper.ensure_development_project(
      client: @rest_client,
      title: "Development Project #{@suffix}",
      auth_token: @config[:dev_token],
      environment: @config[:environment],
      ads: @ads
    )
    @project = project_helper.project

    @prod_rest_client = LcmConnectionHelper.production_server_connection
    @prod_ads = ConfigurationHelper.create_development_datawarehouse(client: @prod_rest_client,
                                                 title: 'Production ADS',
                                                 auth_token: @config[:prod_token])

    @test_context = {
      release_table_name: 'some_release_tabele_name',
      workspace_table_name: 'some_workspace_table_name',
      basic_segment: basic_segment,
      development_pid: @project.obj_id,
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: 'user_data',
      data_product: data_product_id,
      jdbc_url: @ads.data['connectionUrl'],
      basic_master_name: basic_master_name,
    }

    template_path = File.expand_path('../params/release_brick_transfer_all.json.erb', __FILE__)
    @test_context[:input_source_type] = 's3'
    prepare_visualisation_object(@rest_client, @project)
    config_path = ConfigurationHelper.create_interpolated_tempfile(template_path, @test_context)
    params = JSON.parse(File.read(config_path))
    @brick_result = GoodData::Bricks::Pipeline.release_brick_pipeline.call(params)
  end

  it 'Transfers the visualisation object' do
    master_ids = @brick_result[:results]['CreateSegmentMasters'].map { |r| r[:master_pid] }
    master_projects = master_ids.map { |id| @prod_rest_client.projects(id) }
    prodVisualizationObject = GoodData::MdObject.query('visualizationObject', GoodData::MdObject, client: @prod_rest_client, project: master_projects.first)
    expect(prodVisualizationObject.first.meta['title']).to eq('Foo')
    expect(prodVisualizationObject.first.content['buckets'].first['items'].first['measure']['title']).to eq('Count of Account')
  end
end