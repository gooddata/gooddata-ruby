# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/core/core'
require 'securerandom'

describe GoodData::GdLogger do
  it "Has GoodData::GdLogger class" do
    expect(GoodData::GdLogger).not_to be(nil)
  end

  let(:logger) { GoodData::GdLogger.new }

  before(:each) do
    logger.logging_on :logger, Logger.new(STDOUT)
    logger.logging_on :errlog, Logger.new(STDERR)
  end

  describe "When logging is turned on" do
    it "should pass message to both loggers" do
      expect(logger.loggers[:logger]).to receive(:add)
      expect(logger.loggers[:errlog]).to receive(:add)
      logger.info("Plain text")
    end
  end

  describe "When using filter" do
    it "should pass message to :errlog logger" do
      expect(logger.loggers[:logger]).not_to receive(:add)
      expect(logger.loggers[:errlog]).to receive(:add)
      logger.add(Logger::INFO, "Plain text", nil, filters: Set[:logger])
    end
  end

  describe "When using modifier" do
    it "it should not modify :errlog and modify :logger" do
      modifier = proc { |message| "Modified " + message }
      expect(logger.loggers[:logger]).to receive(:add).with(1, "Modified Plain text", nil)
      expect(logger.loggers[:errlog]).to receive(:add).with(1, "Plain text", nil)
      logger.add(Logger::INFO, "Plain text", nil, modifiers: { :logger => modifier })
    end
  end

  describe "When using different levels" do
    it "should prefer individual level over global" do
      logger.level = Logger::ERROR
      logger.level Logger::INFO, :logger
      expect(logger.loggers[:logger].info?).to be_truthy
      expect(logger.loggers[:errlog].info?).to be_falsey
    end
  end

  describe "When logging is turned off" do
    it "all loggers should be of type NilLogger" do
      logger.logging_off :logger
      logger.logging_off :errlog
      expect(logger.loggers[:logger]).to be_instance_of(GoodData::NilLogger)
      expect(logger.loggers[:errlog]).to be_instance_of(GoodData::NilLogger)
    end
  end
end
