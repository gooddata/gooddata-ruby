class LcmConnectionHelper
  class << self
    def production_server_connection
      self.server(which: :prod_server)
    end

    def development_server_connection
      self.server(which: :dev_server)
    end

    # Creates connection client to server according to specified enviroment
    #
    # @param [Symbol] which is either `:dev_server` or `:prod_server`
    # @return [GoodData::Rest::Client] connection client to specified server
    def server(which: :dev_server)
      connection_parameters = {
        username: environment[:username],
        password: environment[:password],
        server: "https://#{environment[which]}"
      }
      GoodData.connect(connection_parameters)
    end

    def environment

      env = GoodData::Environment::ConnectionHelper::LCM_ENVIRONMENT
      ret = env.dup
      encrypted = [:dev_token, :prod_token, :vertica_dev_token, :vertica_prod_token, :password]
      encrypted.each do |key|
        ret[key] = GoodData::Helpers.decrypt(env[key], ENV['GD_SPEC_PASSWORD'])
      end
      ret
    end

    def env_name
      ENV['GD_ENV'] || 'testing'
    end
  end
end
