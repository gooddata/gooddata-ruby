# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'securerandom'

module GoodData
  module Helpers
    module CryptoHelper
      class << self
        def generate_password
          sprinkle(SecureRandom.base64(32))
        end

        private

        # Pseudo-randomly "sprinkles" the given string
        # with 4 character groups (digit, lower case,
        # upper case, symbols).
        # @param [String] password
        def sprinkle(password)
          password_dup = password.dup
          positions = 0..password.size
          password_dup.insert(rand(positions), digit)
          password_dup.insert(rand(positions), lower)
          password_dup.insert(rand(positions), upper)
          password_dup.insert(rand(positions), symbol)
          password_dup
        end

        def digit
          (0..9).to_a.sample.to_s
        end

        def lower
          ('a'..'z').to_a.sample
        end

        def upper
          ('A'..'Z').to_a.sample
        end

        def symbol
          '!@#$%&/()+?*'.chars.sample
        end
      end
    end
  end
end
