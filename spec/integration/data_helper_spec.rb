# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/data_helper'
require 'gooddata/exceptions/invalid_env_error'

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

describe 'data helper', :vcr do
  before(:each) do
    @data_helper = GoodData::Helpers::DataSource.new(type: :redshift)
  end

  it 'failed to connect to redshift with RUBY platform' do
    if RUBY_PLATFORM =~ /java/
      file_path = @data_helper.realize(basic_params)
      data = File.open('spec/data/redshift_data.csv').read
      expect(data).to eq File.open(file_path).read
    else
      expect { @data_helper.realize(basic_params) }.to raise_error(GoodData::InvalidEnvError)
    end
  end

end
