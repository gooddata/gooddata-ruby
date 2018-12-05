# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'spec_helper'

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/logger_middleware'

describe GoodData::Bricks::LoggerMiddleware do
  let(:app) { double(:app) }
  let(:logger) { double(Logger) }

  before(:all) do
    @original_logger = GoodData.logger
  end

  before do
    subject.app = app
    allow(app).to receive(:call)
    allow(Logger).to receive(:new) { logger }
    allow(logger).to receive(:info)
    allow(logger).to receive(:level=)
  end

  after(:all) do
    GoodData.logger = @original_logger
  end

  it "Has GoodData::Bricks::LoggerMiddleware class" do
    GoodData::Bricks::LoggerMiddleware.should_not be(nil)
  end

  context 'when HTTP_LOGGING parameter set to true' do
    let(:params) { { 'HTTP_LOGGING' => 'true' } }

    it 'turns http logging on' do
      expect(GoodData).to receive(:logging_http_on)
      subject.call(params)
    end
  end

  context 'GDC_LOG_LEVEL' do
    let(:params) { { 'GDC_LOG_LEVEL' => log_level } }

    context 'when set' do
      let(:log_level) { 'warn' }
      it 'sets the specified log level' do
        expect(logger).to receive(:level=).with(log_level)
        subject.call(params)
        expect(logger).to eq(GoodData.logger)
      end
    end

    context 'when not set' do
      let(:log_level) { nil }
      it 'sets info log level' do
        expect(logger).to receive(:level=).with('info')
        subject.call(params)
        expect(logger).to eq(GoodData.logger)
      end
    end
  end

  describe '.call' do
    tmp_dir = Dir.mktmpdir
    log_dir = tmp_dir + '/logs'
    execution_id = 'execid'
    let(:params) { { 'GDC_EXECUTION_ID' => execution_id, 'GDC_LOG_DIRECTORY' => log_dir } }

    it 'set MSF compatible file logger' do
      subject.call(params)
      expect(File.directory?(log_dir))
      expect(logger).to eq(GoodData.logger)
    end
  end
end
