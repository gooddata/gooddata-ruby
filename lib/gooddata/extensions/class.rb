# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.
module ClassExtensions
  refine Class do
    def short_name
      name.split('::').last
    end

    def descendants
      ObjectSpace.each_object(Class).select do |klass|
        klass < self
      end
    end
  end
end
