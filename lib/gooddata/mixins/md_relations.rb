# encoding: UTF-8

module GoodData
  module Mixin
    module MdRelations
      def dependency(uri, key = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        GoodData::MdObject.dependency(uri, key, opts)
      end

      # Checks for dependency
      def dependency?(type, obj, opts = { :client => GoodData.connection, :project => GoodData.project })
        GoodData::MdObject.dependency?(type, self, obj, opts)
      end

      # Returns which objects uses this MD resource
      def usedby(key = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        dependency("#{project.md['usedby2']}/#{obj_id}", key, opts)
      end

      alias_method :used_by, :usedby

      # Returns which objects this MD resource uses
      def using(key = nil, opts = { :client => GoodData.connection, :project => GoodData.project })
        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = opts[:project]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        dependency("#{project.md['using2']}/#{obj_id}", key, opts)
      end

      def usedby?(obj, opts = { :client => GoodData.connection, :project => GoodData.project })
        GoodData::MdObject.used_by?(self, obj, opts)
      end

      alias_method :used_by?, :usedby?

      # Checks if obj is using this MD resource
      def using?(obj, opts = { :client => GoodData.connection, :project => GoodData.project })
        dependency?(:using, obj, opts)
      end
    end
  end
end
