# encoding: UTF-8

module GoodData
  module Mixin
    module Author
      # Gets author of an object
      #
      # @return [GoodData::Profile] object author
      def author
        tmp = client.get(author_uri)
        client.create(GoodData::Profile, tmp, project: project)
      end

      # Gets author URI of an object
      #
      # @return [String] object author URI
      def author_uri
        meta['author']
      end
    end
  end
end
