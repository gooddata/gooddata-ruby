require 'active_support/core_ext/hash'

class BrickRunner
  class << self
    def user_filters_brick(opts)
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call script_params opts
    end

    def users_brick(opts)
      GoodData::Bricks::Pipeline.users_brick_pipeline.call script_params opts
    end

    def release_brick(opts)
      result = GoodData::Bricks::Pipeline.release_brick_pipeline.call script_params opts
      master_ids = result[:results]['CreateSegmentMasters'].map { |r| r[:master_pid] }
      fetch_projects(master_ids, opts) if opts[:client]
    end

    def provisioning_brick(opts)
      result = GoodData::Bricks::Pipeline.provisioning_brick_pipeline.call script_params opts
      client_pids = result[:params][:synchronize].first[:to].map(&:pid)
      fetch_projects(client_pids, opts) if opts[:client]
    end

    def rollout_brick(opts)
      result = GoodData::Bricks::Pipeline.rollout_brick_pipeline.call script_params opts
      client_pids = result[:params][:synchronize].first[:to].map(&:pid)
      fetch_projects(client_pids, opts) if opts[:client]
    end

    def schedule_brick(brick_name, service_project, opts)
      opts[:template_path] = "../../integration/params/#{brick_name}.json.erb" unless opts[:template_path]
      decoded_params = GoodData::Helpers.decode_params(script_params(opts))
      params, hidden_params = extract_hidden_params(decoded_params)
      params.delete('gd_encoded_hidden_params')
      deploy_string = "${PRODUCTION_APPSTORE}:branch/lcm2:/apps/#{brick_name}"

      process = service_project.deploy_process(
        deploy_string,
        name: "test of #{brick_name}"
      )

      schedule = process.create_schedule(
        opts[:run_after],
        ProcessHelper::DEPLOY_NAME,
        params: params,
        hidden_params: hidden_params
      )

      puts "#{brick_name} schedule URI: #{schedule.uri}"
      schedule
    end

    private

    def extract_hidden_params(params)
      hidden_params = params.dup
      params = hidden_params.slice!(
        'GDC_USERNAME',
        'GDC_PASSWORD',
        's3_secret_access_key',
        's3_access_key'
      )
      [params, hidden_params]
    end

    def fetch_projects(pids, opts)
      client = opts[:client]
      pids.map { |id| client.projects(id) }
    end

    def script_params(opts = {})
      template_path = opts[:template_path]
      test_context = opts[:context]

      config_path = ConfigurationHelper.create_interpolated_tempfile(
        File.expand_path(template_path, __FILE__),
        test_context
      )
      JSON.parse(File.read(config_path))
    end
  end
end
