module GoodData
  module Mixin
    module UriGetter
      def uri
        data && data['links'] && data['links']['self']
      end
    end
  end
end
