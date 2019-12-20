# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/data_helper'
require 'gooddata/exceptions/invalid_env_error'

iam_params = {
  "redshift_client"=> {
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
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_project_users"
  }
}

basic_params = {
  "redshift_client"=> {
    "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
    "authentication"=> {
      "basic"=> {
      "userName"=> "cornflake",
      "password"=> ConnectionHelper::SECRETS[:redshift_password]
      }
    },
    "database"=> "dev",
    "schema"=> "lcm_integration_test"
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_project_users"
  }
}

basic_params_without_schema = {
  "redshift_client"=> {
    "url"=> "jdbc:redshift://explorer.cbrgkmwhlu9v.us-east-2.redshift.amazonaws.com:5439",
    "authentication"=> {
      "basic"=> {
        "userName"=> "cornflake",
        "password"=> ConnectionHelper::SECRETS[:redshift_password]
      }
    },
    "database"=> "dev"
  },
  "input_source"=> {
    "type"=> "redshift",
    "query"=> "SELECT * FROM lcm_test"
  }
}

describe 'data helper', :vcr do
  before(:each) do
    @data_helper = GoodData::Helpers::DataSource.new(type: :redshift)
  end

  it 'connect to redshift with IAM authentication' do
    file_path = @data_helper.realize(iam_params)
    data = File.open('spec/data/redshift_data.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication' do
    file_path = @data_helper.realize(basic_params)
    data = File.open('spec/data/redshift_data.csv').read
    expect(data).to eq File.open(file_path).read
  end

  it 'connect to redshift with BASIC authentication without schema' do
    file_path = @data_helper.realize(basic_params_without_schema)
    data = File.open('spec/data/redshift_data.csv').read
    expect(data).to eq File.open(file_path).read
  end
end
