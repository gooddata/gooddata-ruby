# encoding: UTF-8

require 'gooddata'
require 'pry'

describe GoodData::Connection, :constraint => 'slow' do

  it "should log in and disconnect" do
    ConnectionHelper::create_default_connection
    GoodData.get("/gdc/md")

    conn = GoodData.connection
    ConnectionHelper.disconnect

    expect{GoodData.connection}.to raise_error
    conn.connected?.should == false
  end

end