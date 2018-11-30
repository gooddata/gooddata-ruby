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

      it "should not mask nil" do
        expect(logger).to receive(level).with(nil)
        subject.send(level, nil)
      end
    end
  end
end
