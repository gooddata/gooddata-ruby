# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'user_filter'

module GoodData
  class MandatoryUserFilter < UserFilter
    class << self
      def [](id, options = { client: GoodData.connection, project: GoodData.project })
        if id == :all
          all(options)
        else
          super
        end
      end

      def all(options = { client: GoodData.connection, project: GoodData.project })
        c = client(options)
        project = options[:project]
        filters = query('userFilter', nil, options)
        count = 1_000
        offset = 0
        user_lookup = {}
        loop do
          result = c.get("/gdc/md/#{project.pid}/userfilters?count=#{count}&offset=#{offset}")
          result['userFilters']['items'].each do |item|
            item['userFilters'].each do |f|
              user_lookup[f] = item['user']
            end
          end
          break if result['userFilters']['length'] < offset
          offset += count
        end
        mufs = filters.map do |filter_data|
          payload = {
            'expression' => filter_data['userFilter']['content']['expression'],
            'related' => user_lookup[filter_data['userFilter']['meta']['uri']],
            'level' => :user,
            'type'  => :filter,
            'uri'   => filter_data['userFilter']['meta']['uri']
          }
          c.create(GoodData::MandatoryUserFilter, payload, project: project)
        end
        mufs.enum_for
      end

      def count(options = { client: GoodData.connection, project: GoodData.project })
        c = client(options)
        project = options[:project]
        c.get(project.md['query'] + '/userfilters/')['query']['entries'].count
      end
    end

    # Creates or updates the mandatory user filter on the server
    #
    # @return [GoodData::MandatoryUserFilter]
    def save
      data = {
        'userFilter' => {
          'content' => {
            'expression' => expression
          },
          'meta' => {
            'category' => 'userFilter',
            'title' => related_uri
          }
        }
      }
      res = client.post(project.md['obj'], data)
      @json[:uri] = res['uri']
    end
  end
end
