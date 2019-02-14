# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/core/core'

describe GoodData::SplunkLogger do
  it "Has GoodData::SplunkLogger class" do
    expect(GoodData::SplunkLogger).not_to be(nil)
  end

  subject { GoodData::SplunkLogger.new STDOUT }

  it "should not print to any output" do
    expect { subject.add(Logger::INFO, nil, "\n") }.not_to output.to_stdout_from_any_process
    expect { subject.add(Logger::INFO, "\n", nil) }.not_to output.to_stdout_from_any_process
  end

  it "should print out given message" do
    expect { subject.info("Plain text") }.to output(/.*Plain text/).to_stdout_from_any_process
  end

  it "should print out given message" do
    expect { subject.info(key: "value") }.to output(/.*key=value/).to_stdout_from_any_process
  end
end
