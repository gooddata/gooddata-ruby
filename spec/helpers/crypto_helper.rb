# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'securerandom'

module GoodData::Helpers
  module CryptoHelper
    class << self
      def generate_password
        SecureRandom.hex(16)
      end
    end
  end
end
