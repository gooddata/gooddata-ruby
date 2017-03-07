# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../metadata'
require_relative '../../core/rest'
require_relative '../../mixins/is_folder'

require_relative 'metadata'

module GoodData
  class Folder < GoodData::MdObject
    include Mixin::IsFolder

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('folder', Folder, options)
      end
    end

    def entries
      (json['folder']['content']['entries'] || []).pmap do |entry|
        res = case json['folder']['content']['type'].first
              when 'fact'
                GoodData::Fact[entry['link'], :client => client, :project => project]
              when 'metric'
                GoodData::Metric[entry['link'], :client => client, :project => project]
              else
                GoodData::MdObject[entry['link'], :client => client, :project => project]
              end
        res
      end
    end

    def type
      json['folder']['content']['type'][0]
    end
  end
end
