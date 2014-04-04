# encoding: UTF-8

require 'gooddata/core/core'

describe GoodData::NilLogger do
  it "Has GoodData::NilLogger class" do
    GoodData::NilLogger.should_not be(nil)
  end
end