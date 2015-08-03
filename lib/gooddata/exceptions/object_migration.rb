# encoding: UTF-8

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
