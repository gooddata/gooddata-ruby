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

end