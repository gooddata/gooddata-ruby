# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

# require 'gooddata/core/core'
require 'gooddata/bricks/middleware/context_logger_decorator'

describe GoodData::ContextLoggerDecorator do
  it "Has GoodData::ContextLoggerDecorator module" do
    expect(GoodData::ContextLoggerDecorator).not_to be(nil)
  end

  ContextManagerMock = Struct.new(:context)

  describe "When dynamically changing source context" do
    let(:context_manager) { ContextManagerMock.new(key: 'val1') }

    it "Should return changed context" do
      logger = Logger.new nil
      logger.extend(GoodData::ContextLoggerDecorator)
      logger.context_source = context_manager
      context_manager.context = { key: 'val2' }
      expect(logger).to receive(:enrich).with(nil, key: 'val2')
      logger.info nil
    end
  end
end
