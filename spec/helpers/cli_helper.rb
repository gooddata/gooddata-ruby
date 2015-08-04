# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/cli/cli'

module GoodData::Helpers
  module CliHelper
    # Execute block and capture its stdou
    # @param block Block to be executed with stdout redirected
    # @returns Captured output as string
    def capture_stdout(&block)
      original_stdout = $stdout
      $stdout = fake = StringIO.new
      begin
        yield
      ensure
        $stdout = original_stdout
      end
      fake.string
    end

    # Run CLI with arguments and return captured stdout
    # @param args Arguments
    # @return Captured stdout
    def run_cli(args = [])
      old = $0
      $0 = 'gooddata'
      res = capture_stdout { GoodData::CLI.main(args) }
      $0 = old
      res
    end
  end
end
