require_relative 'support/constants'
require_relative 'support/configuration_helper'
require_relative 'support/connection_helper'
require_relative 'support/lcm_helper'
require_relative 'support/project_helper'
require_relative 'support/s3_helper'
require_relative 'brick_runner'

def uniq_label_with_value(project, value_count)
  blacklists = $generated_uniq_labels_with_value || {}
  blacklist = blacklists[project.pid] || []

  atts = project.attributes.to_a.sort_by(&:identifier)
  attribute = atts.shift while !attribute || attribute.date_attribute? || !attribute.primary_label || (blacklist.include? attribute)
  label = attribute.primary_label
  sorted_values = label.values.to_a.sort { |x, y| x[:value] <=> y[:value] }
  notempty = sorted_values.select { |v| !v[:value].empty? }
  values = notempty.slice(0, value_count)

  blacklists[project.pid] = blacklist.push attribute
  $generated_uniq_labels_with_value = blacklists
  [label, values.map { |v| v[:value] }]
end

def set_up_random_muf_data(project, user_data, complexity = 2)
  label, values = uniq_label_with_value project, complexity
  puts "Settings up MUF referencing value #{values} of attribute #{label.title}"
  mufs = user_data.map do |u|
    values.map do |v|
      {
        login: u[:custom_login],
        client_id: u[:client_id],
        value: v,
        label_id: label.identifier
      }
    end
  end.flatten
  Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(mufs), Support::S3Helper::USER_FILTERS_KEY)
  mufs
end

def test_user_filters_brick(options = {})
  test_context = options[:test_context]
  mufs = options[:mufs]
  projects = options[:projects]
  muf_complexity = options[:muf_complexity] || 2

  BrickRunner.user_filters_brick context: test_context, template_path: '../params/user_filters_brick_e2e.json.erb'

  projects.each do |p|
    filters = p.user_filters.to_a
    expect(filters.length).to eq(mufs.count / projects.count / muf_complexity)
    mufs.each do |u|
      expect(filters.find { |f| f.related.email == u[:login] })
    end
  end
end

def test_users_brick(options = {})
  test_context = options[:test_context]
  projects = options[:projects]
  user_data = options[:user_data]

  BrickRunner.users_brick context: test_context, template_path: '../params/users_brick_e2e.json.erb'

  projects.each do |p|
    users = p.users.to_a
    expect(users.length).to eq((user_data.count / projects.count) + 1) # rubydev+admin is in the projects as well (as he is the admin)
    # TODO: check the data is the same
  end
end

describe 'the user provisioning flow' do
  projects_amount = 1
  user_amount = 2

  before(:all) do
    @suffix = ConfigurationHelper.suffix
    @rest_client = LcmConnectionHelper.production_server_connection
    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    project = @rest_client.domain('staging2-lcm-prod').clients('ClientProjectC').project
    project.add_data_permissions([], no_sanitize: true)
    @projects = projects_amount.times.map do |n|
      opts = {
        client: @rest_client,
        title: "LCM User provisioning end-to-end spec project #{@suffix} #{n}",
        auth_token: LcmConnectionHelper.environment[:prod_token],
        environment: 'TESTING'
      }
      project_helper = Support::ProjectHelper.create(opts)
      puts 'creating LDM and stuff'
      project_helper.create_ldm
      project_helper.load_data
      puts "created project #{project_helper.project.pid}"
      project_helper.project
    end

    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @data_product = @domain.create_data_product(id: "userprov-e2e-testing-dataproduct-#{@suffix}")
    @master_project = @rest_client.create_project(title: "userprov-e2e-testing-master-#{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
    @segment = @data_product.create_segment(segment_id: "userprov-e2e-testing-segment-#{@suffix}", master_project: @master_project)
    @clients = @projects.each_with_index.map do |p, i|
      @segment.create_client(id: "userprov-e2e-testing-client-#{i}-#{@suffix}", project: p)
    end
    @user_data = @clients.map do |c|
      Array.new(user_amount) do |n|
        {
          custom_login: "lcm-userprov-e2e-UPPERCASE-#{n}@gooddata.com",
          client_id: c.client_id,
          position: 'developer'
        }
      end
    end.flatten
    Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(@user_data), Support::S3Helper::USERS_KEY)
    @user_data.map do |u|
      @domain.add_user(login: u[:custom_login]) unless @domain.users u[:custom_login]
    end

    @mufs = set_up_random_muf_data(@projects.first, @user_data)

    @test_context = {
      project_id: @projects.first.pid, # this doesn't really matter for the runtime
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: Support::S3Helper::USER_FILTERS_KEY,
      data_source: 's3',
      column_name: 'value',
      sync_mode: 'sync_domain_client_workspaces',
      data_product: @data_product.data_product_id,
      label: @mufs.first[:label_id],
      users_brick_input: {
        s3_bucket: Support::S3Helper::BUCKET_NAME,
        s3_endpoint: Support::S3Helper::S3_ENDPOINT,
        s3_key: Support::S3Helper::USERS_KEY
      }
    }
  end

  describe '1 - initial MUF setup' do
    it 'provisions MUFs' do
      test_user_filters_brick(projects: @projects,
                              test_context: @test_context,
                              mufs: @mufs)
    end
  end

  describe '2 - initial user setup' do
    it 'provisions users' do
      test_users_brick(projects: @projects,
                       test_context: @test_context,
                       user_data: @user_data)
    end
  end

  describe '3 - subsequent user setup after modification' do
    it 'provisions users' do
      user_data = @user_data.map do |c|
        c.merge('position' => 'manager')
      end
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(user_data), Support::S3Helper::USERS_KEY)
      test_users_brick(projects: @projects,
                       test_context: @test_context,
                       user_data: user_data)
    end
  end

  describe '4 - subsequent MUF setup after modification' do
    it 'provisions MUFs' do
      muf_complexity = 4
      mufs = set_up_random_muf_data(@projects.first, @user_data, muf_complexity)
      test_context = @test_context.merge(label: mufs.first[:label_id])
      test_user_filters_brick(projects: @projects,
                              test_context: test_context,
                              mufs: mufs,
                              muf_complexity: muf_complexity)
    end
  end

  after(:all) do
    @projects.map(&:delete)
    @data_product.delete(force: true)
  end
end
