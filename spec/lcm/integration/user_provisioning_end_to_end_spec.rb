require_relative 'support/constants'
require_relative 'support/configuration_helper'
require_relative 'support/connection_helper'
require_relative 'support/lcm_helper'
require_relative 'support/project_helper'
require_relative 'support/s3_helper'
require_relative 'brick_runner'

def uniq_label_with_value(project)
  blacklists = $generated_uniq_labels_with_value || {}
  blacklist = blacklists[project.pid] || []

  atts = project.attributes.to_a
  attribute = atts.shift while !attribute || attribute.date_attribute? || !attribute.primary_label || (blacklist.include? attribute)
  label = attribute.primary_label
  value = label.values.find { |v| !v[:value].empty? }

  blacklists[project.pid] = blacklist.push attribute
  $generated_uniq_labels_with_value = blacklists
  [label, value[:value]]
end

shared_context 'user filters brick' do
  it 'updates user filters' do
    BrickRunner.user_filters_brick context: @test_context, template_path: '../params/user_filters_brick_e2e.json.erb'

    @projects.each do |p|
      filters = p.user_filters.to_a
      expect(filters.length).to eq(@mufs.count / @projects.count)
      @mufs.each do |u|
        expect(filters.find { |f| f.related.email == u[:login] })
      end
    end
  end
end

shared_context 'users brick' do
  it 'updates users' do
    BrickRunner.users_brick context: @test_context, template_path: '../params/users_brick_e2e.json.erb'

    @projects.each do |p|
      users = p.users.to_a
      expect(users.length).to eq((@user_data.count / @projects.count) + 1) # rubydev+admin is in the projects as well (as he is the admin)
      # TODO: check the data is the same
    end
  end
end

describe 'the user provisioning flow' do
  $projects_amount = 1
  $muf_complexity = 1
  $user_amount = 1

  before(:all) do
    @suffix = ConfigurationHelper.suffix
    @rest_client = LcmConnectionHelper.production_server_connection
    @domain = @rest_client.domain(LcmConnectionHelper.environment[:prod_organization])
    @projects = $projects_amount.times.map do |n|
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
    @data_product = @domain.data_products('default')
    @master_project = @rest_client.create_project(title: "Test MASTER project for #{@suffix}", auth_token: LcmConnectionHelper.environment[:prod_token])
    @segment = @data_product.create_segment(segment_id: "testing-segment-#{@suffix}", master_project: @master_project)

    @user_data = @projects.map do |c|
      Array.new($user_amount) do |n|
        {
          login: "lcm-userprov-e2e-UPPERCASE-#{n}@gooddata.com",
          project_id: c.pid,
          position: 'developer'
        }
      end
    end.flatten
    Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(@user_data), Support::S3Helper::USERS_KEY)
    @user_data.map do |u|
      @domain.add_user(login: u[:login]) unless @domain.users u[:login]
    end

    label, value = uniq_label_with_value @projects.first
    @mufs = @user_data.map do |u|
      m = {}
      m[:login] = u[:login]
      m[:project_id] = u[:project_id]
      m[label.title] = value
      m
    end.flatten
    Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(@mufs), Support::S3Helper::USER_FILTERS_KEY)

    @test_context = {
      project_id: @projects.first.pid, # this doesn't really matter for the runtime
      config: LcmConnectionHelper.environment,
      s3_bucket: Support::S3Helper::BUCKET_NAME,
      s3_endpoint: Support::S3Helper::S3_ENDPOINT,
      s3_key: Support::S3Helper::USER_FILTERS_KEY,
      sync_mode: 'sync_multiple_projects_based_on_pid',
      data_product: 'default',
      users_brick_input: {
        s3_bucket: Support::S3Helper::BUCKET_NAME,
        s3_endpoint: Support::S3Helper::S3_ENDPOINT,
        s3_key: Support::S3Helper::USERS_KEY
      }
    }
  end

  describe '1 - initial MUF setup' do
    it_behaves_like 'user filters brick'
  end

  describe '2 - initial user setup' do
    it_behaves_like 'users brick'
  end

  describe 'modify the user input' do
    it 'does it' do
      @user_data.map! do |c|
        c['position'] = 'manager'
        c
      end
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(@user_data), Support::S3Helper::USERS_KEY)
    end
  end

  describe '3 - subsequent user setup' do
    it_behaves_like 'users brick'
  end

  describe 'modify the MUF input' do
    it 'does it' do
      label, value = uniq_label_with_value @projects.first
      @mufs.map! do |m|
        m[label.title] = value
        m
      end
      Support::S3Helper.upload_file(ConfigurationHelper.csv_from_hashes(@mufs), Support::S3Helper::USER_FILTERS_KEY)
    end
  end

  describe '4 - subsequent MUF setup' do
    it_behaves_like 'user filters brick'
  end

  after(:all) do
    @projects.map(&:delete)
  end
end
