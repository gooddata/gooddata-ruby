# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'spec_helper'
require 'gooddata/core/splunk_logger_decorator'
require 'gooddata/core/nil_logger'

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/logger_middleware'
require 'gooddata/bricks/middleware/mask_logger_decorator'

require 'remote_syslog_logger'

describe GoodData::Bricks::LoggerMiddleware do
  let(:app) { double(:app) }
  let(:logger) { double(Logger) }
  let(:temp_splunk_logger) { double(GoodData::SplunkLoggerDecorator) }
  let(:splunk_logger) { double(GoodData::Bricks::MaskLoggerDecorator) }
  let(:nil_logger) { double(GoodData::NilLogger) }

  before(:all) do
    @original_logger = GoodData.logger
  end

  before do
    subject.app = app
    allow(app).to receive(:call)
    allow(Logger).to receive(:new) { logger }
    allow(logger).to receive(:info)
    allow(logger).to receive(:level=)
    allow(GoodData::SplunkLoggerDecorator).to receive(:new) { temp_splunk_logger }
    allow(temp_splunk_logger).to receive(:level=)
    allow(GoodData::Bricks::MaskLoggerDecorator).to receive(:new) { splunk_logger }
    allow(splunk_logger).to receive(:info)
    allow(splunk_logger).to receive(:level=)
    allow(GoodData::NilLogger).to receive(:new) { nil_logger }
  end

  after(:all) do
    GoodData.logger = @original_logger
  end

  it "Has GoodData::Bricks::LoggerMiddleware class" do
    expect(GoodData::Bricks::LoggerMiddleware).not_to be_nil
  end

  context 'when HTTP_LOGGING parameter set to true' do
    let(:params) { { 'HTTP_LOGGING' => 'true' } }

    it 'turns http logging on' do
      expect(GoodData).to receive(:logging_http_on)
      subject.call(params)
    end
  end

  context 'when default' do
    let(:params) { { it_does: 'not matter' } }
    let(:node_name) { '12.12.12.12' }

    it 'turns splunk logging on' do
      expect(GoodData).to receive(:splunk_logging_on).with(splunk_logger)
      subject.call(params)
    end

    it 'creates a syslog forwarder' do
      ENV['NODE_NAME'] = node_name
      expect(RemoteSyslogLogger).to receive(:new).with(node_name, 514, program: 'lcm_ruby_brick', facility: 'local2')
      subject.call(params)
    end

    context 'when SPLUNK_LOG_LEVEL set' do
      let(:log_level) { 'warn' }
      let(:params) { { 'SPLUNK_LOG_LEVEL' => log_level, 'SPLUNK_LOGGING' => 'true' } }
      it 'sets the specified log level' do
        expect(temp_splunk_logger).to receive(:level=).with(log_level)
        subject.call(params)
      end
    end

    context 'when SPLUNK_LOG_PATH set' do
      let(:log_path) { 'path' }
      let(:params) { { 'SPLUNK_LOG_PATH' => log_path, 'SPLUNK_LOGGING' => 'true' } }
      it 'sets the specified log level' do
        expect(GoodData::SplunkLoggerDecorator).to receive(:new).with(logger)
        subject.call(params)
      end
    end
  end

  context 'when splunk logging is disabled' do
    let(:params) { { 'NO_SPLUNK_LOGGING' => 'true' } }

    it 'turns splunk logging off' do
      expect(GoodData).to_not receive(:splunk_logging_on)
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
      expect(logger.class).to eq(GoodData.logger.class)
    end
  end
end
