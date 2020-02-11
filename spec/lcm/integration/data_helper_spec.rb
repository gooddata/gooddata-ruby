# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/data_helper'
require 'gooddata/exceptions/invalid_env_error'

iam_params = {
  "redshift_client"=> {
    "connection"=> {
      "url"=> "jdbc:redshift:iam://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
      "authentication"=> {
        "iam"=> {
          "dbUser"=> "redshiftdevunloader",
          "accessKeyId"=> ConnectionHelper::SECRETS[:redshift_access_key],
          "secretAccessKey"=> ConnectionHelper::SECRETS[:redshift_secret_key]
        }
      },
      "database"=> "dev",
      "schema"=> "lcm_integration_test"
    }
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_project_users order by client_id"
  }
}

basic_params = {
  "redshift_client"=> {
    "connection"=> {
      "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
      "authentication"=> {
        "basic"=> {
          "userName"=> "cornflake",
          "password"=> ConnectionHelper::SECRETS[:redshift_password]
        }
      },
      "database"=> "dev",
      "schema"=> "lcm_integration_test"
    }
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_project_users order by client_id"
  }
}

basic_params_dynamic_source = {
  "redshift_client"=> {
    "connection"=> {
      "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
      "authentication"=> {
        "basic"=> {
          "userName"=> "cornflake",
          "password"=> ConnectionHelper::SECRETS[:redshift_password]
        }
      },
      "database"=> "dev",
      "schema"=> "lcm_integration_test"
    }
  },
  "dynamic_params" => {
    "input_source"=> {
      "type"=> "redshift",
      "query"=> "SELECT * FROM lcm_project_users order by client_id"
    }
  }
}

basic_params_url_parameters = {
  "redshift_client"=> {
    "connection"=> {
      "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439/?ssl=true",
      "authentication"=> {
        "basic"=> {
          "userName"=> "cornflake",
          "password"=> ConnectionHelper::SECRETS[:redshift_password]
        }
      },
      "database"=> "dev",
      "schema"=> "lcm_integration_test"
    }
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_project_users order by client_id"
  }
}

basic_params_without_schema = {
  "redshift_client"=> {
    "connection"=> {
      "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
      "authentication"=> {
        "basic"=> {
          "userName"=> "cornflake",
          "password"=> ConnectionHelper::SECRETS[:redshift_password]
        }
      },
      "database"=> "dev"
    }
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_test order by client_id"
  }
}

describe 'data helper', :vcr do

  it 'connect to redshift with IAM authentication' do
    data_helper = GoodData::Helpers::DataSource.new(iam_params['input_source'])
    file_path = data_helper.realize(iam_params)
    data = File.open('spec/data/redshift_data2.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication' do
    data_helper = GoodData::Helpers::DataSource.new(basic_params['input_source'])
    file_path = data_helper.realize(basic_params)
    data = File.open('spec/data/redshift_data2.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication without schema' do
    data_helper = GoodData::Helpers::DataSource.new(basic_params_without_schema['input_source'])
    file_path = data_helper.realize(basic_params_without_schema)
    data = File.open('spec/data/redshift_data.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication and dynamic source' do
    data_helper = GoodData::Helpers::DataSource.new(basic_params_dynamic_source['dynamic_params']['input_source'])
    file_path = data_helper.realize(basic_params_dynamic_source)
    data = File.open('spec/data/redshift_data2.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication and url has parameter' do
    data_helper = GoodData::Helpers::DataSource.new(basic_params_url_parameters['input_source'])
    file_path = data_helper.realize(basic_params_url_parameters)
    data = File.open('spec/data/redshift_data2.csv').read
    expect(data).to eq File.open(file_path).read
  end
end
