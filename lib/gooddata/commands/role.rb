# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../core/core'

module GoodData
  module Command
    class Role
      class << self
        def list(_pid, opts = { :client => GoodData.connection, :project => GoodData.project })
          p = opts[:project]
          fail ArgumentError, 'No :project specified' if p.nil?

          project = GoodData::Project[p, opts]
          fail ArgumentError, 'Wrong :project specified' if project.nil?

          roles_response = client.get("/gdc/projects/#{project.pid}/roles")

          roles = {}
          roles_response['projectRoles']['roles'].each do |role_uri|
            r = client.get(role_uri)
            identifier = r['projectRole']['meta']['identifier']
            roles[identifier] = {
              :user_uri => r['projectRole']['links']['roleUsers'],
              :uri => role_uri
            }
          end
          roles
        end
      end
    end
  end
end
