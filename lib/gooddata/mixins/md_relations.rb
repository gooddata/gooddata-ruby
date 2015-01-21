# encoding: UTF-8

module GoodData
  module Mixin
    module MdRelations
      def dependency(uri, key = nil, opts = { :client => client, :project => project })
        GoodData::MdObject.dependency(uri, key, opts)
      end

      # Checks for dependency
      def dependency?(type, obj, opts = { :client => client, :project => project })
        GoodData::MdObject.dependency?(type, self, obj, opts)
      end

      # Returns which objects uses this MD resource
      def usedby(key = nil, opts = { :client => client, :project => project })
        dependency("#{project.md['usedby2']}/#{obj_id}", key, { :client => client, :project => project }.merge(opts))
      end

      alias_method :used_by, :usedby

      # Returns which objects this MD resource uses
      def using(key = nil, opts = { :client => client, :project => project })
        dependency("#{project.md['using2']}/#{obj_id}", key, { :client => client, :project => project }.merge(opts))
      end

      def usedby?(obj, opts = { :client => client, :project => project })
        GoodData::MdObject.used_by?(self, obj, opts)
      end

      alias_method :used_by?, :usedby?

      # Checks if obj is using this MD resource
      def using?(obj, opts = { :client => client, :project => project })
        dependency?(:using, obj, opts)
      end
    end
  end
end
