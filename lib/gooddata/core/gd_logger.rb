# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class GDLogger < Logger
    attr_accessor :log_to_splunk

    def add(severity, message, progname)
      super(severity, message, progname)
      GoodData.splunk_logger.add(severity, message, progname) if log_to_splunk.to_b
    end
  end
end
