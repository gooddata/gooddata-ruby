# encoding: UTF-8

module GoodData
  class NoProjectError < RuntimeError
    DEFAULT_MSG = 'You have to provide "project_id". You can either provide it through -p flag or even better way is to fill it in in your Goodfile under key "project_id". If you just started a project you have to create it first. One way might be through "gooddata project build"'

    def initialize(msg = DEFAULT_MSG)
      super(msg)
    end
  end
end
