# encoding: UTF-8

module GoodData
  module Model
    # GoodData REST API categories
    LDM_CTG = 'ldm'
    LDM_MANAGE_CTG = 'ldm-manage2'

    # Model naming conventions
    FIELD_PK = 'id'
    FK_SUFFIX = '_id'
    FACT_COLUMN_PREFIX = 'f_'
    DATE_COLUMN_PREFIX = 'dt_'
    TIME_COLUMN_PREFIX = 'tm_'
    LABEL_COLUMN_PREFIX = 'nm_'
    ATTRIBUTE_FOLDER_PREFIX = 'dim'
    ATTRIBUTE_PREFIX = 'attr'
    LABEL_PREFIX = 'label'
    FACT_PREFIX = 'fact'
    DATE_FACT_PREFIX = 'dt'
    DATE_ATTRIBUTE = 'date'
    DATE_ATTRIBUTE_DEFAULT_DISPLAY_FORM = 'mdyy'
    TIME_FACT_PREFIX = 'tm.dt'
    TIME_ATTRIBUTE_PREFIX = 'attr.time'
    FACT_FOLDER_PREFIX = 'ffld'
  end
end
