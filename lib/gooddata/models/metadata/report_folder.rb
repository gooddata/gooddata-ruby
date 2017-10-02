# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class ReportFolder < GoodData::MdObject
    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide
      # to pull in full objects. This is desirable from the usability
      # POV but unfortunately has negative impact on performance so it
      # is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { client: GoodData.connection, project: GoodData.project })
        query('domain', ReportFolder, options)
      end

      def create(title, options = { client: GoodData.connection, project: GoodData.project })
        client, project = GoodData.get_client_and_project(options)

        payload = {
          domain: {
            content: {
              entries: []
            },
            meta: {
              title: title,
              summary: '',
              tags: '',
              deprecated: 0
            }
          }
        }
        client.create(self, GoodData::Helpers.stringify_keys(payload), project: project)
      end
    end

    # Get all reports from the current folder
    def reports
      json['domain']['content']['entries'].pmap do |entry|
        GoodData::Report[entry['link'], client: client, project: project]
      end
    end
  end
end
