require 'gooddata/cli/cli'

describe GoodData::CLI do
  it "Has working 'api' command" do
    args = %w(api)

    GoodData::CLI.main(args)
  end

  it "Has working 'api info' command" do
    args = %w(api info)

    GoodData::CLI.main(args)
  end

  it "Has working 'api get /gdc' command" do
    args = %w(api get /gdc)

    GoodData::CLI.main(args)
  end
end