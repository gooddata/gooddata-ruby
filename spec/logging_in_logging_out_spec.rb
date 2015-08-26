# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'
require 'pry'

describe GoodData::Rest::Connection, :constraint => 'slow' do

  it "should log in and disconnect" do
    client = ConnectionHelper::create_default_connection
    expect(client).to be_kind_of(GoodData::Rest::Client)

    client.get("/gdc/md")

    client.disconnect
  end

  it 'should be able to log in with user name and password as params' do
    client = GoodData.connect(GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME, GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD,
                              server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
                              verify_ssl: false)
    client.disconnect
  end

  it 'should be able to log in with user name and password as hash' do
    client = GoodData.connect(username: GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME,
                              password: GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD,
                              server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
                              verify_ssl: false)
    client.disconnect
  end

  it 'should be able to log in with login and password as hash' do
    client = GoodData.connect(login: GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME,
                              password: GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD,
                              server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
                              verify_ssl: false)
    client.disconnect
  end

  it 'should be able to pass additional params in hash' do
    client = GoodData.connect(login: GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME,
                              password: GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD,
                              server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
                              webdav_server: 'https://some_random_server/',
                              verify_ssl: false)
    expect(client.opts[:webdav_server]).to eq 'https://some_random_server/'
    client.disconnect
  end

  it 'should be able to pass additional params in hash when used login/pass' do
    client = GoodData.connect(GoodData::Environment::ConnectionHelper::DEFAULT_USERNAME, GoodData::Environment::ConnectionHelper::DEFAULT_PASSWORD,
                              server: GoodData::Environment::ConnectionHelper::DEFAULT_SERVER,
                              webdav_server: 'https://some_random_server/',
                              verify_ssl: false)
    expect(client.opts[:webdav_server]).to eq 'https://some_random_server/'
    client.disconnect
  end

  it "should log in and disconnect with SST" do
    regular_client = ConnectionHelper::create_default_connection
    sst = regular_client.connection.sst_token

    sst_client = GoodData.connect(sst_token: sst, verify_ssl: false)
    expect(sst_client.projects.count).to be > 0
    sst_client.disconnect

    regular_client.disconnect
  end

  it "should log in and disconnect with SST with additional params" do
    regular_client = ConnectionHelper::create_default_connection
    sst = regular_client.connection.sst_token

    sst_client = GoodData.connect(sst_token: sst, verify_ssl: false, webdav_server: 'https://some_random_server/')
    expect(sst_client.projects.count).to be > 0
    expect(sst_client.opts[:webdav_server]).to eq 'https://some_random_server/'
    sst_client.disconnect

    regular_client.disconnect
  end

  it "should be able to regenerate TT" do
    regular_client = ConnectionHelper::create_default_connection
    projects = regular_client.projects
    regular_client.connection.cookies[:cookies].delete('GDCAuthTT')
    regular_client.get('/gdc/md')
    expect(regular_client.connection.cookies[:cookies]).to have_key 'GDCAuthTT'
  end
end
