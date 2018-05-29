class LcmConnectionHelper
  ENVIRONMENTS = {
    staging: { dev_server: 'staging-lcm-dev.intgdc.com',
               prod_server: 'staging-lcm-prod.intgdc.com',
               dev_token: GoodData::Helpers.decrypt("yuyngLi/Q1TUTQ6L2ZhfHez2Nob1mjTCRY0nw5VoBm8=\n", ENV['GD_SPEC_PASSWORD']),
               prod_token: GoodData::Helpers.decrypt("6saP85fb+8c+z8FoIyJO2SGrr+40hJdEZfKQNpd4k9w=\n", ENV['GD_SPEC_PASSWORD']),
               vertica_dev_token: GoodData::Helpers.decrypt("N1V1EcYeWEGTOgUX620Qaim12ksw+Rhrkad43dWYwsw=\n", ENV['GD_SPEC_PASSWORD']),
               vertica_prod_token: GoodData::Helpers.decrypt("EoKrobIZT8ZtFeHFtGFybcYNgPwsqwGOhyALRb2UKcw=\n", ENV['GD_SPEC_PASSWORD']),
               dev_organization: 'staging-lcm-dev',
               prod_organization: 'staging-lcm-prod',
               username: 'rubydev+admin@gooddata.com',
               password: GoodData::Helpers.decrypt("8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n", ENV['GD_SPEC_PASSWORD']) },
    testing: { dev_server: 'staging2-lcm-dev.intgdc.com',
               prod_server: 'staging2-lcm-prod.intgdc.com',
               dev_token: GoodData::Helpers.decrypt("AQOWrGqDxTqScOITS1oNt0tJDDVrIlYWaD7UkoHKecQ=\n", ENV['GD_SPEC_PASSWORD']),
               prod_token: GoodData::Helpers.decrypt("ohgnrJFCu4s8/3tP22Hqr2x93xwONt1kRWlMNY9nyBk=\n", ENV['GD_SPEC_PASSWORD']),
               vertica_dev_token: GoodData::Helpers.decrypt("076gMCX1eLiYzbSp6dZdQZKg+x2cM6Ft7muBAf13bRE=\n", ENV['GD_SPEC_PASSWORD']),
               vertica_prod_token: GoodData::Helpers.decrypt("lbTi+wmEy3U2gNqiHEplL52NK+HO3Xb1rUpghIJmUWk=\n", ENV['GD_SPEC_PASSWORD']),
               dev_organization: 'staging2-lcm-dev',
               prod_organization: 'staging2-lcm-prod',
               username: 'rubydev+admin@gooddata.com',
               password: GoodData::Helpers.decrypt("8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n", ENV['GD_SPEC_PASSWORD']) },
    development: { dev_server: 'staging3-lcm-dev.intgdc.com',
                   prod_server: 'staging3-lcm-prod.intgdc.com',
                   dev_token: GoodData::Helpers.decrypt("krw3m2jQREVy9GRJdJi4f4sXcF6r/L515s3Frv8l4eY=\n", ENV['GD_SPEC_PASSWORD']),
                   prod_token: GoodData::Helpers.decrypt("qq9Mgu0OPqZDpKJyG7R2SM20uvL5Kho+8eAGTvkSTuM=\n", ENV['GD_SPEC_PASSWORD']),
                   vertica_dev_token: GoodData::Helpers.decrypt("wZ3cvWN8XT40aV9x8xzigrXSbrYGwhH8FaEf6m6IqkA=\n", ENV['GD_SPEC_PASSWORD']),
                   vertica_prod_token: GoodData::Helpers.decrypt("VV4J66eCRu74qip2ZH2/OVaqgO8gCZ655xXQgiTfrKo=\n", ENV['GD_SPEC_PASSWORD']),
                   dev_organization: 'staging3-lcm-dev',
                   prod_organization: 'staging3-lcm-prod',
                   username: 'rubydev+admin@gooddata.com',
                   password:  GoodData::Helpers.decrypt("8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n", ENV['GD_SPEC_PASSWORD']) },
    performance: { dev_server: 'perf-lcm-dev.intgdc.com',
                   prod_server: 'perf-lcm-prod.intgdc.com',
                   dev_token: GoodData::Helpers.decrypt("KP3+C5et9WMmYI9zsYUgj9XqvorBEEMmflrAP2jauh/s92O8oaDKnJ7RIaQy\npU1W\n", ENV['GD_SPEC_PASSWORD']),
                   prod_token: GoodData::Helpers.decrypt("BSH8a/JFKkwwwRpGLZTb2ViOxdeZ+VW0KUny9Mq4AuEalBdeoCbxsfcjCM3W\n6JrK\n", ENV['GD_SPEC_PASSWORD']),
                   vertica_dev_token: GoodData::Helpers.decrypt("pdFK5RReapLYI0bzM2kz0gtORGJyKiy3tn05uawulcJIP3wDsHQaFjpNJbVF\niVJf\n", ENV['GD_SPEC_PASSWORD']),
                   vertica_prod_token: GoodData::Helpers.decrypt("d11tBQNJL586wIHelDf1ORvJNEk83GxOPG4f/Azgj3Tdzti4PB5skf6mDVSl\nBB6g\n", ENV['GD_SPEC_PASSWORD']),
                   dev_organization: 'perf-lcm-dev',
                   prod_organization: 'perf-lcm-prod',
                   username: 'rubydev+admin@gooddata.com',
                   password: GoodData::Helpers.decrypt("8dP7cCR0LqAyyo4S817bt8bHKfuIteVCW4Y76sGkx78=\n", ENV['GD_SPEC_PASSWORD']) } }.freeze

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
      ENVIRONMENTS[env_name.downcase.to_sym]
    end

    def env_name
      ENV['GD_ENV'] || 'testing'
    end
  end
end
