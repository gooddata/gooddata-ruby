# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
require_relative '../enum'

module GoodData
  module LCM2
    module Type
      class SynchronizeLDM < EnumType
        def values
          %w(diff_against_clients
             diff_against_master
             diff_against_master_with_fallback)
        end
      end
    end
  end
end
