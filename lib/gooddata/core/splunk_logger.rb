# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'logger'

module GoodData
  # Logger that process given message to format readable by splunk
  class SplunkLogger < Logger
    def hash_to_string(hash)
      hash.map { |pair| " #{pair[0]}=#{pair[1]}" }.join ""
    end

    # If the given message or progname is an instance of Hash, it's reformatted to splunk readable format.
    # In case that the message or the progname contain new line character log won't be printed out.
    # Otherwise splunk worker wouldn't process it correctly.
    def add(severity, message = nil, progname = nil)
      message = hash_to_string(message) if message.is_a? Hash
      progname = hash_to_string(progname) if progname.is_a? Hash
      super(severity, message, progname) unless (progname && progname.include?("\n")) || (message && message.include?("\n"))
    end
  end
end
