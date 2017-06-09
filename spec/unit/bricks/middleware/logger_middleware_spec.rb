# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/logger_middleware'

describe GoodData::Bricks::LoggerMiddleware do
  it "Has GoodData::Bricks::LoggerMiddleware class" do
    GoodData::Bricks::LoggerMiddleware.should_not be(nil)
  end

  context 'when HTTP_LOGGING parameter set to true' do
    let(:params) { { 'HTTP_LOGGING' => 'true' } }
    let(:app) { double(:app) }

    before do
      subject.app = app
      allow(app).to receive(:call)
    end

    it 'turns http logging on' do
      expect(GoodData).to receive(:logging_http_on)
      subject.call(params)
    end
  end
end
