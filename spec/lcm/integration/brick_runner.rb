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
      pp result
      master_ids = result[:results]['CreateSegmentMasters'].map { |r| r[:master_pid] }
      fetch_projects(master_ids, opts) if opts[:client]
    end

    def provisioning_brick(opts)
      result = GoodData::Bricks::Pipeline.provisioning_brick_pipeline.call script_params opts
      pp result
      client_pids = result[:params][:synchronize].first[:to].map(&:pid)
      fetch_projects(client_pids, opts) if opts[:client]
    end

    def rollout_brick(opts)
      result = GoodData::Bricks::Pipeline.rollout_brick_pipeline.call script_params opts
      pp result
      client_pids = result[:params][:synchronize].first[:to].map(&:pid)
      fetch_projects(client_pids, opts) if opts[:client]
    end

    private

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
