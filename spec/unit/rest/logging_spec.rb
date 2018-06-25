# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/rest/rest'

require_relative '../../../lib/gooddata/bricks/middleware/logger_middleware'

describe 'logging with GoodData::SplunkLogger' do
  it 'should log buffered to STDERR' do
    logger = GoodData::SplunkLogger.new STDERR, GoodData::SplunkLogger::FILE_MODE
    logger.info("Hello world")
  end
end
