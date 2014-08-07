# encoding: UTF-8

module GoodData
  module Mixin
    module MdFinders
      def find_by_tag(tag)
        self[:all, client: client].select { |r| r.tags.split(',').include?(tag) }
      end

      def find_first_by_title(title, options = {})
        all = self[:all, options.merge(full: false)]
        item = if title.is_a?(Regexp)
                 all.find { |r| r['title'] =~ title }
               else
                 all.find { |r| r['title'] == title }
               end
        self[item['link'], options] unless item.nil?
      end

      # Finds a specific type of the object by title. Returns all matches. Returns full object.
      #
      # @param title [String] title that has to match exactly
      # @param title [Regexp] regular expression that has to match
      # @return [Array<GoodData::MdObject>] Array of MdObject
      def find_by_title(title, options = {})
        all = self[:all, options.merge(full: false)]
        items = if title.is_a?(Regexp)
                  all.select { |r| r['title'] =~ title }
                else
                  all.select { |r| r['title'] == title }
                end
        items.pmap { |item| self[item['link'], options] unless item.nil? }
      end
    end
  end
end
