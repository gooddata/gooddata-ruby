# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/client'
require 'gooddata/models/model'

describe GoodData::Helpers do
  describe '#find_goodfile' do
    it 'works' do
      GoodData::Helpers.find_goodfile.should_not be_nil
    end
  end
end
