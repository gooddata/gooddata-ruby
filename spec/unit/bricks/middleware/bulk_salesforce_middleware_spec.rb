# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/bulk_salesforce_middleware'

describe GoodData::Bricks::BulkSalesforceMiddleware do
  it "Has GoodData::Bricks::BulkSalesforceMiddleware class" do
    GoodData::Bricks::BulkSalesforceMiddleware.should_not == nil
  end
end
