require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has GoodData::CLI class" do
    GoodData::CLI.should_not == nil
  end

  it "Has GoodData::CLI::main() working" do
    GoodData::CLI.main([])
  end
end