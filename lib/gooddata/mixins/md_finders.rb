# encoding: UTF-8

module GoodData
  module Mixin
    module MdFinders
      # Finds a specific type of the object by identifier. Returns first match. Returns full object.
      #
      # @param title [String] identifier that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_first_by_identifier(identifier, options = { :client => GoodData.connection, :project => GoodData.project })
        all = self[:all, options.merge(full: false)]
        item = if identifier.is_a?(Regexp)
                 all.find { |r| r.identifier =~ identifier }
               else
                 all.find { |r| r.identifier == identifier }
               end
        self[item.uri, options] unless item.nil?
      end

      # Finds a specific type of the object by identifier. Returns all matches. Returns full object.
      #
      # @param title [String] identifier that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_by_identifier(identifier, options = { :client => GoodData.connection, :project => GoodData.project })
        all = self[:all, options]
        items = if identifier.is_a?(Regexp)
                  all.select { |r| r.title =~ identifier }
                else
                  all.select { |r| r.title == identifier }
                end
        items.pmap { |item| self[item.uri, options] unless item.nil? }
      end

      def find_by_tag(tag, opts = { :client => GoodData.connection, :project => GoodData.project })
        c = client || opts[:client]

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError 'Wrong :project specified' if project.nil?

        self[:all, client: c, project: project].select { |r| r.tags.split(',').include?(tag) }
      end

      # Finds a specific type of the object by title. Returns first match. Returns full object.
      #
      # @param title [String] title that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_first_by_title(title, options = { :client => GoodData.connection, :project => GoodData.project })
        all = self[:all, options]
        item = if title.is_a?(Regexp)
                 all.find { |r| r.title =~ title }
               else
                 all.find { |r| r.title == title }
               end
        self[item.uri, options] unless item.nil?
      end

      # Finds a specific type of the object by title. Returns all matches. Returns full object.
      #
      # @param title [String] title that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_by_title(title, options = { :client => GoodData.connection, :project => GoodData.project })
        all = self[:all, options]
        items = if title.is_a?(Regexp)
                  all.select { |r| r.title =~ title }
                else
                  all.select { |r| r.title == title }
                end
        items.pmap { |item| self[item.uri, options] unless item.nil? }
      end
    end
  end
end
