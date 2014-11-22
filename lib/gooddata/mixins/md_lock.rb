# encoding: UTF-8

module GoodData
  module Mixin
    module Lockable
      # Locks an object. Locked object cannot be changed by certain users.
      #
      # @return [GoodData::Mixin::Lockable]
      def lock
        meta['locked'] = 1
        self
      end

      # Sames as #lock. Locks an object and immediately saves it.
      #
      # @return [GoodData::Mixin::Lockable]
      def lock!
        lock
        save
      end

      # Unlocks an object.
      #
      # @return [GoodData::Mixin::Lockable]
      def unlock
        meta.delete('locked')
        self
      end

      # Same as #unlock. Unlocks an object and immediately saves it
      #
      # @return [GoodData::Mixin::Lockable]
      def unlock!
        unlock
        save
      end

      # Locks an object with all used objects. The types of objects that are affected by locks
      # are dashboards, reports and metrics. This means that if you lock a dashboard by this method
      # all used reports and metrics are also locked. If you lock a report all used metrics are also
      # locked. The current object is reloaded. This means that the #locked? will return true.
      #
      # @return [GoodData::Mixin::Lockable]
      def lock_with_dependencies!
        client.post("/gdc/internal/projects/#{project.pid}/objects/setPermissions",
                    permissions: {
                      lock: true,
                      items: [uri]
                    })
        reload!
      end

      # Unlocks an object with all used objects. The types of objects that are affected by locks
      # are dashboards, reports and metrics. This means that if you unlock a dashboard by this method
      # all used reports and metrics are also unlocked. If you unlock a report all used metrics are also
      # unlocked. The current object is unlocked as well. Beware that certain objects might be in use in
      # multiple contexts. For example one metric can be used in several reports. This method performs no
      # checks to determine if an object should stay locked or not.
      #
      # @return [GoodData::Mixin::Lockable]
      def unlock_with_dependencies!
        using('report').pmap { |link| project.reports(link['link']) }.select(&:locked?).pmap(&:unlock!)
        using('metric').pmap { |link| project.metrics(link['link']) }.select(&:locked?).pmap(&:unlock!)
        using('projectDashboard').pmap { |link| project.dashboards(link['link']) }.select(&:locked?).pmap(&:unlock!)
        unlock!
      end

      # Returns true if an object is locked. False otherwise.
      #
      # @return [Boolean]
      def locked?
        meta['locked'] == 1
      end

      # Returns true if an object is unlocked. False otherwise.
      #
      # @return [Boolean]
      def unlocked?
        !locked?
      end
    end
  end
end
