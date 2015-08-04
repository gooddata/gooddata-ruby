# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
