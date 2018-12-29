# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/middleware/context_manager'

describe GoodData::ContextManager do
  it "Has GoodData::ContextManager class" do
    expect(GoodData::ContextManager).not_to be(nil)
  end

  # Wrapper class for ContextManager module
  class ContextManagerWrapper
    include GoodData::ContextManager
  end

  it "Should be empty" do
    context_manager = ContextManagerWrapper.new
    context_manager.initialize_context
    expect(context_manager.context).to eq(
      api_version: GoodData.version,
      log_v: 0,
      component: 'lcm.ruby',
      action: GoodData::ContextManager::UNDEFINED,
      brick: GoodData::ContextManager::UNDEFINED,
      status: GoodData::ContextManager::STATUS_OUTSIDE,
      execution_id: GoodData::ContextManager::UNDEFINED
    )
  end

  it "Should contain some context" do
    action = "LCM::TestAction"
    brick = "LCM::TestBrick"
    execution_id = "abcd1234"
    time1 = Time.new(2019, 1, 1, 0, 0, 0)
    time2 = Time.new(2019, 1, 1, 0, 0, 55)

    context_manager = ContextManagerWrapper.new
    context_manager.initialize_context
    context_manager.brick = brick
    context_manager.execution_id = execution_id
    context_manager.start_action action, nil, time1
    expect(context_manager.context(time2)).to eq(
      api_version: GoodData.version,
      log_v: 0,
      component: 'lcm.ruby',
      brick: brick,
      action: action,
      status: GoodData::ContextManager::STATUS_IN_PROGRESS,
      execution_id: execution_id,
      time: 55_000
    )
  end
end
