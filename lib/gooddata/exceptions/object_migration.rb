# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  # Project Not Found
  class ObjectsMigrationError < RuntimeError
    DEFAULT_MSG = 'Object migration failed.'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end

  class ObjectsExportError < ObjectsMigrationError
    DEFAULT_MSG = 'Exporting objects failed.'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end

  class ObjectsImportError < ObjectsMigrationError
    DEFAULT_MSG = 'Importing objects failed.'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
