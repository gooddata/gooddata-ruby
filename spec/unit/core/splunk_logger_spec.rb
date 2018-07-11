# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/core/core'
require 'securerandom'

describe GoodData::SplunkLogger do
  after(:each) do
    subject.logs = ""
  end

  it "Has GoodData::SplunkLogger class" do
    GoodData::SplunkLogger.should_not be(nil)
  end

  context "When initialized" do
    it "should have empty log buffer" do
      expect(subject.logs).not_to be_nil
      expect(subject.logs).to be_empty
    end
  end

  context "When using buffer mode" do
    before do
      subject.file_output_on
      subject.buffering_on
    end

    it "should push logs to buffer" do
      subject.info "Hello world"
      expect(subject.logs).not_to be_empty
      expect { subject.flush }.to output.to_stderr_from_any_process
      expect(subject.logs).to be_empty
    end
  end

  context "When not using buffer mode" do
    before do
      subject.file_output_on
      subject.buffering_off
    end

    it "should print logs to output file" do
      expect {subject.info "Hello world"}.to output.to_stderr_from_any_process
      expect(subject.logs).to be_empty
      expect { subject.flush }.not_to output.to_stderr_from_any_process
    end
  end

  context "When filtering params is on" do
    before do
      subject.file_output_on
      subject.buffering_on
    end

    it "should filter params from output" do
      subject.params_filter(:user => { :user_name => "admin", :password => "1234"}, :secret_keys => ["key1", "key2", "hash_key" => "hash_val"])
      subject.info "password = 1234, username = admin, username = admin, key1, hash_key, hash_val"

      expect(subject.logs).not_to include "1234"
      expect(subject.logs).not_to include "admin"
      expect(subject.logs).to include "password = ****, username = ****, username = ****, ****, hash_key, ****"
    end
  end

  context "Writing to file" do
    let(:file_name) { '_splunk.log' }
    let(:logger) { GoodData::SplunkLogger.new(file_name, :file_output => true, :buffering => false) }

    before do
      logger.buffering_on
    end

    it "should log to file _splunk.log" do
      logger.info"Hello world"

      log = logger.logs.dup
      logger.flush

      file = File.open file_name
      content = file.read
      file.close
      expect(content).to include log
      File.delete file_name
    end
  end
end
