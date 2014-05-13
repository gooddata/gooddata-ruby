# encoding: UTF-8

require 'gooddata'

describe GoodData::SmallGoodZilla do
  
  MAQL_EXAMPLE = 'SELECT SUM(#"Amount") WHERE @"Date"=#"X" AND ?"Snapshot EOP"=1'
  FACTS = {
    "Amount" => "a",
    "X" => "x"
  }
  ATTRIBUTES = {
    "Date" => "d"
  }
  METRICS = {
    "Snapshot EOP" => "snap"
  }
  DICT = {
    :facts => FACTS,
    :attributes => ATTRIBUTES,
    :metrics => METRICS,
  }
  
  it "should parse metrics out of the string" do
    x = GoodData::SmallGoodZilla.get_facts(MAQL_EXAMPLE)
    x.should == ["Amount", "X"]
  end

  it "should parse attributes out of the string" do
    x = GoodData::SmallGoodZilla.get_attributes(MAQL_EXAMPLE)
    x.should == ["Date"]
  end

  it "should parse metrics out of the string" do
    x = GoodData::SmallGoodZilla.get_metrics(MAQL_EXAMPLE)
    x.should == ["Snapshot EOP"]
  end

  it "should interpolate the values" do
    
    interpolated = GoodData::SmallGoodZilla.interpolate({
      :facts => ["Amount", "X"],
      :attributes => ["Date"],
      :metrics => ["Snapshot EOP"]
    }, DICT)
    
    interpolated.should == {
      :facts => [["Amount", "a"], ["X", "x"]],
      :attributes => [["Date", "d"]],
      :metrics => [["Snapshot EOP", "snap"]]
    }
  end

  it "should return interpolated metric" do
    interpolated = GoodData::SmallGoodZilla.interpolate_metric(MAQL_EXAMPLE, DICT)
    interpolated.should == "SELECT SUM([a]) WHERE [d]=[x] AND [snap]=1"
  end

  it "should be able to parse several ids correctly." do
    metric = "SELECT SUM(
        CASE
          WHEN ![attr.customer_profiles.profile_id] = [/gdc/md/pxa3aic06undadkc5s7t5lxpne11vgyt/obj/257/elements?id=65] THEN ![fact.perfomance_by_campaign_id.general_score_1]
          WHEN ![attr.customer_profiles.profile_id] = [/gdc/md/pxa3aic06undadkc5s7t5lxpne11vgyt/obj/257/elements?id=50] THEN ![fact.perfomance_by_campaign_id.general_score_5]
          WHEN ![attr.customer_profiles.profile_id] = [/gdc/md/pxa3aic06undadkc5s7t5lxpne11vgyt/obj/257/elements?id=20]  THEN ![fact.perfomance_by_campaign_id.general_score_12]
        END)"
    GoodData::SmallGoodZilla.get_ids(metric).should == [
      "attr.customer_profiles.profile_id",
      "fact.perfomance_by_campaign_id.general_score_1",
      "fact.perfomance_by_campaign_id.general_score_5",
      "fact.perfomance_by_campaign_id.general_score_12"
    ]
  end

end