class LcmConnectionHelper
  ENVIRONMENTS = {
    staging: { dev_server: 'staging-lcm-dev.intgdc.com',
               prod_server: 'staging-lcm-prod.intgdc.com',
               dev_token: "yuyngLi/Q1TUTQ6L2ZhfHez2Nob1mjTCRY0nw5VoBm8=\n",
               prod_token: "6saP85fb+8c+z8FoIyJO2SGrr+40hJdEZfKQNpd4k9w=\n",
               vertica_dev_token: "N1V1EcYeWEGTOgUX620Qaim12ksw+Rhrkad43dWYwsw=\n",
               vertica_prod_token: "EoKrobIZT8ZtFeHFtGFybcYNgPwsqwGOhyALRb2UKcw=\n",
               dev_organization: 'staging-lcm-dev',
               prod_organization: 'staging-lcm-prod',
               username: 'rubydev+admin@gooddata.com',
               password: "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n" },
    testing: { dev_server: 'staging2-lcm-dev.intgdc.com',
               prod_server: 'staging2-lcm-prod.intgdc.com',
               dev_token: "AQOWrGqDxTqScOITS1oNt0tJDDVrIlYWaD7UkoHKecQ=\n",
               prod_token: "ohgnrJFCu4s8/3tP22Hqr2x93xwONt1kRWlMNY9nyBk=\n",
               vertica_dev_token: "076gMCX1eLiYzbSp6dZdQZKg+x2cM6Ft7muBAf13bRE=\n",
               vertica_prod_token: "lbTi+wmEy3U2gNqiHEplL52NK+HO3Xb1rUpghIJmUWk=\n",
               dev_organization: 'staging2-lcm-dev',
               prod_organization: 'staging2-lcm-prod',
               username: 'rubydev+admin@gooddata.com',
               password: "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n" },
    development: { dev_server: 'staging3-lcm-dev.intgdc.com',
                   prod_server: 'staging3-lcm-prod.intgdc.com',
                   dev_token: "krw3m2jQREVy9GRJdJi4f4sXcF6r/L515s3Frv8l4eY=\n",
                   prod_token: "qq9Mgu0OPqZDpKJyG7R2SM20uvL5Kho+8eAGTvkSTuM=\n",
                   vertica_dev_token: "wZ3cvWN8XT40aV9x8xzigrXSbrYGwhH8FaEf6m6IqkA=\n",
                   vertica_prod_token: "VV4J66eCRu74qip2ZH2/OVaqgO8gCZ655xXQgiTfrKo=\n",
                   dev_organization: 'staging3-lcm-dev',
                   prod_organization: 'staging3-lcm-prod',
                   username: 'rubydev+admin@gooddata.com',
                   password:  "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n" },
    performance: { dev_server: 'perf-lcm-dev.intgdc.com',
                   prod_server: 'perf-lcm-prod.intgdc.com',
                   dev_token: "KP3+C5et9WMmYI9zsYUgj9XqvorBEEMmflrAP2jauh/s92O8oaDKnJ7RIaQy\npU1W\n",
                   prod_token: "BSH8a/JFKkwwwRpGLZTb2ViOxdeZ+VW0KUny9Mq4AuEalBdeoCbxsfcjCM3W\n6JrK\n",
                   vertica_dev_token: "pdFK5RReapLYI0bzM2kz0gtORGJyKiy3tn05uawulcJIP3wDsHQaFjpNJbVF\niVJf\n",
                   vertica_prod_token: "d11tBQNJL586wIHelDf1ORvJNEk83GxOPG4f/Azgj3Tdzti4PB5skf6mDVSl\nBB6g\n",
                   dev_organization: 'perf-lcm-dev',
                   prod_organization: 'perf-lcm-prod',
                   username: 'rubydev+admin@gooddata.com',
                   password: "8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n" }
  }.freeze

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
      env = ENVIRONMENTS[env_name.downcase.to_sym]
      encrypted = [:dev_token, :prod_token, :vertica_dev_token, :vertica_prod_token, :password]
      encrypted.each do |key|
        env[key] = GoodData::Helpers.decrypt(env[key], ENV['GD_SPEC_PASSWORD'])
      end
      env
    end

    def env_name
      ENV['GD_ENV'] || 'testing'
    end
  end
end
