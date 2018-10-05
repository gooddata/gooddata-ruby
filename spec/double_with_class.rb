# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module RSpec
  module Mocks
    module ExampleMethods
      # Creates a double and mocks its #class method to match the object
      def double_with_class(klass)
        d = double(klass)
        allow(d).to receive(:class).and_return(klass)
        d
      end
    end
  end
end
