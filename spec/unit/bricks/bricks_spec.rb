require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'

describe GoodData::Bricks do
  it "Has GoodData::Bricks::Brick class", :integration => true do
    GoodData::Bricks::Brick.should_not == nil
  end
end
