# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'spec_helper'

require 'gooddata/bricks/middleware/mask_logger_decorator'

describe GoodData::Bricks::MaskLoggerDecorator do
  let(:logger) { double(Logger) }
  let(:values_to_mask) { %w[secret_password sensitive] }
  subject { GoodData::Bricks::MaskLoggerDecorator.new(logger, values_to_mask) }

  %i[debug error fatal info unknown warn].each do |level|
    describe ".#{level}" do
      it "should mask" do
        expect(logger).to receive(level).with("This is ******.")
        subject.send(level, "This is secret_password.")
      end

      it "nothing to mask" do
        expect(logger).to receive(level).with("This is message won't be masked.")
        subject.send(level, "This is message won't be masked.")
      end

      it "should mask 2 values" do
        expect(logger).to receive(level).with("This is ****** which is ****** information.")
        subject.send(level, "This is secret_password which is sensitive information.")
      end

      it "should recursively mask structured data" do
        expect(logger).to receive(level).with("{:key1=>[\"This is ******.\"], :key2=>{:inner=>\"Also ******\"}}")
        subject.send(level, key1: ["This is secret_password."], key2: { inner: "Also sensitive" })
      end
      it "should not mask nil" do
        expect(logger).to receive(level).with(nil)
        subject.send(level, nil)
      end
    end
  end

  describe ".extract_values" do
    it "should extract String" do
      values_to_extract = "secret_password"
      extracted_values = GoodData::Bricks::MaskLoggerDecorator.extract_values(values_to_extract)
      expect(extracted_values).to eq(["secret_password"])
    end

    it "should extract Array" do
      values_to_extract = %w[secret_password sensitive]
      extracted_values = GoodData::Bricks::MaskLoggerDecorator.extract_values(values_to_extract)
      expect(extracted_values).to eq(%w[secret_password sensitive])
    end

    it "should extract Hash" do
      values_to_extract = { key1: "secret_password", key2: "sensitive" }
      extracted_values = GoodData::Bricks::MaskLoggerDecorator.extract_values(values_to_extract)
      expect(extracted_values).to eq(%w[secret_password sensitive])
    end

    it "should extract structured data" do
      values_to_extract = { key1: ["secret_password"], key2: { inner: "sensitive" } }
      extracted_values = GoodData::Bricks::MaskLoggerDecorator.extract_values(values_to_extract)
      expect(extracted_values).to eq(%w[secret_password sensitive])
    end

    it "shouldn't extract not String types" do
      values_to_extract = [nil, true, 342, 4.2]
      extracted_values = GoodData::Bricks::MaskLoggerDecorator.extract_values(values_to_extract)
      expect(extracted_values).to eq([])
    end
  end

  context 'when logging complex object' do
    subject { GoodData::Bricks::MaskLoggerDecorator.new(logger, ['secret']) }
    let(:printed_object) { double('secret') }
    before do
      printed_object.instance_variable_set :@secret, 'secret'
      string = printed_object.to_s
      allow(printed_object).to receive(:to_s) { string + "#{@secret} secret" }
    end

    it 'should mask data in object attributes and names' do
      expect(subject.mask(printed_object)).to_not include('secret')
    end
  end
end
