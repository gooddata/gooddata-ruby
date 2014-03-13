require 'gooddata'
require 'pry'

describe GoodData::Connection, :constraint => 'slow' do

  it "should log in and disconnect" do

    GoodData.connect("svarovsky+gem_tester@gooddata.com", "jindrisska")
    GoodData.get("/gdc/md")

    conn = GoodData.connection
    GoodData.disconnect
    expect{GoodData.connection}.to raise_error
    conn.connected?.should == false
  end

end