# encoding: UTF-8

require 'gooddata'
require 'pry'

describe GoodData::Rest::Connection, :constraint => 'slow' do

  it "should log in and disconnect" do
    client = ConnectionHelper::create_default_connection
    expect(client).to be_kind_of(GoodData::Rest::Client)

    client.get("/gdc/md")

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

  it "should be able to regenerate TT" do
    regular_client = ConnectionHelper::create_default_connection
    projects = regular_client.projects
    regular_client.connection.cookies[:cookies].delete('GDCAuthTT')
    regular_client.get('/gdc/md')
    expect(regular_client.connection.cookies[:cookies]).to have_key 'GDCAuthTT'
  end
end
