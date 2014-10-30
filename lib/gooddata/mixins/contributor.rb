# encoding: UTF-8

module GoodData
  module Mixin
    module Contributor
      # Gets Project Role Contributor
      #
      # @return [GoodData::Profile] Project Role Contributor
      def contributor
        url = meta['contributor']
        tmp = client.get url
        GoodData::Profile.new(tmp)
      end
    end
  end
end
