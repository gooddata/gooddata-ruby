require 'gooddata/bricks/bricks'

describe GoodData::Bricks do
  it "Has GoodData::Bricks::Brick class" do
    GoodData::Bricks::Brick.should_not == nil
  end
end

class String
  def pigize
  end
end

describe String, "#pigize" do
  it "Pigizes string" do
    1.should == 1
  end
end