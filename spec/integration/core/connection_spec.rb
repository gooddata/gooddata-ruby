# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/connection'

describe GoodData::Rest::Connection, :vcr do
  before(:all) do
    USERNAME = ConnectionHelper::DEFAULT_USERNAME
    PASSWORD = ConnectionHelper::SECRETS[:default_password]
  end

  it "Has DEFAULT_URL defined" do
    expect(GoodData::Rest::Connection::DEFAULT_URL).to be_a(String)
  end

  it "Has LOGIN_PATH defined" do
    expect(GoodData::Rest::Connection::LOGIN_PATH).to be_a(String)
  end

  it "Has TOKEN_PATH defined" do
    expect(GoodData::Rest::Connection::TOKEN_PATH).to be_a(String)
  end

  describe '#connect' do
    it "Connects using username and password" do
      c = GoodData.connect(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::SECRETS[:default_password], :verify_ssl => 0)
      expect(c).to be_a(GoodData::Rest::Client)
      c.disconnect
    end
  end

  describe '#disconnect' do
    it "Connects using username and password" do
      c = GoodData.connect(ConnectionHelper::DEFAULT_USERNAME, ConnectionHelper::SECRETS[:default_password], :verify_ssl => 0)
      c.disconnect
    end
  end

  describe '#generate_request_id' do
    it "Generates a non-empty string" do
      c = ConnectionHelper.create_default_connection

      # generate a request id, and pass it to a request
      id = c.generate_request_id
      c.get('/gdc/md', :request_id => id)

      expect(id).to be_a(String)
      expect(id).not_to be_empty

      c.disconnect
    end
  end

  describe 'error handling' do
    it 'prints the error message' do
      c = ConnectionHelper.create_default_connection

      begin
        c.post('/gdc/projects', 'project' => {})
      rescue StandardError => e
        expect { puts e }.to output(/400 Bad Request/).to_stdout
      end
    end
  end
end
