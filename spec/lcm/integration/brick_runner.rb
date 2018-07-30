class BrickRunner
  class << self
    def user_filters_brick(opts)
      GoodData::Bricks::Pipeline.user_filters_brick_pipeline.call script_params opts
    end

    def users_brick(opts)
      GoodData::Bricks::Pipeline.users_brick_pipeline.call script_params opts
    end

    private

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
