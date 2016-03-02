# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Mixin
    module MdGrantees
      def grantees(opts = {})
        permission = opts[:permission]
        params = permission ? { permission: permission } : {}
        client.get(uri + '/grantees', params: params)
      end

      def grant(opts = {})
        change_permission(opts.merge(operation: :add))
      end

      def revoke(opts = {})
        change_permission(opts.merge(operation: :remove))
      end

      def change_permission(opts)
        permission = opts[:permission]
        member = opts[:member]
        op = opts[:operation]
        klasses = [GoodData::Profile, GoodData::UserGroup, GoodData::Membership]
        fail "Permission has to be set. Current value '#{permission}'" unless permission
        fail 'Member has to be either user or group' unless klasses.any? { |c| member.is_a?(c) }
        payload = {
          granteeURIs: {
            items: [
              { aclEntryURI: { permission: permission, grantee: member.uri } }
            ]
          }
        }
        client.post(uri + '/grantees/' + op.to_s, payload)
      end
    end
  end
end
