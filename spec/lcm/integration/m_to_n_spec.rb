require_relative 'support/connection_helper'
require_relative 'support/configuration_helper'
require_relative 'support/s3_helper'

require_relative 'support/project_helper'
require_relative 'shared_examples_for_synchronization_bricks'

require 'active_support'
require 'active_support/core_ext'

describe 'Contains M to N relation' do
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

    domain = @rest_client.domain(@config[:dev_organization])
    domain.data_products(:all).each { |d| d.delete(force: true) }

    project_helper = Support::ProjectHelper.create(
      client: @rest_client,
      title: "Development Project for m to n #{@suffix}",
      auth_token: @config[:dev_token],
      environment: @config[:environment],
      ads: @ads
    )

    @project = project_helper.project
    maql = '
      CREATE DATASET {dataset.x};
      CREATE DATASET {dataset.y};
      CREATE ATTRIBUTE {attr.x} AS KEYS {f_x.id} FULLSET;
      CREATE ATTRIBUTE {attr.y} AS KEYS {f_y.id} FULLSET, {f_x.y_id} MULTIVALUE;

      CREATE FACT {fact.x} AS {f_x.f};
      CREATE FACT {fact.y} AS {f_y.f};

      ALTER DATASET {dataset.x} ADD {attr.x}, {fact.x};
      ALTER DATASET {dataset.y} ADD {attr.y}, {fact.y};

      ALTER ATTRIBUTE {attr.x} ADD LABELS {label.x} VISUAL(TITLE "Test Label") AS {f_x.label_x};
      ALTER ATTRIBUTE {attr.y} ADD LABELS {label.y} VISUAL(TITLE "Test Labelis") AS {f_y.label_y};
    '
    @project.execute_maql maql
  end

  it 'before update from blueprint' do
    expect(m_to_ns(@project)).to include(['dataset.y', 'dataset.x'])
  end

  it 'after update from blueprint' do
    @project.update_from_blueprint(@project.blueprint)
    expect(m_to_ns(@project)).to include(['dataset.y', 'dataset.x'])
  end

  after(:all) do
    @project.delete
  end
end

def m_to_ns(project)
  options = { include_ca: true }
  result = project.client.get("/gdc/projects/#{project.pid}/model/view", params: { includeDeprecated: true, includeGrain: true, includeCA: options[:include_ca] })
  polling_url = result['asyncTask']['link']['poll']
  model = project.client.poll_on_code(polling_url, options)
  result = model['projectModelView']['model']['projectModel']['datasets'].map do |d|
    if !d['dataset']['bridges'].nil?
      [d['dataset']['identifier'], d['dataset']['bridges'].join]
    else
      []
    end
  end
  result
end
