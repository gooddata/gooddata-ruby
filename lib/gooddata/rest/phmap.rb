# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Rest
    class Connection
      # PH_MAP for wildcarding of URLs in reports
      PH_MAP = [
        ['/gdc/account/profile/{id}', %r{/gdc/account/profile/[\w]+}],
        ['/gdc/account/login/{id}', %r{/gdc/account/login/[\w]+}],
        ['/gdc/account/domains/{id}/users?login={login}', %r{/gdc/account/domains/[\w\d-]+/users\?login=[^&$]+}],
        ['/gdc/account/domains/{id}', %r{/gdc/account/domains/[\w\d-]+}],

        ['/gdc/projects/{id}/execute', %r{/gdc/projects/[\w]+/execute}],

        ['/gdc/datawarehouse/instances/{id}', %r{/gdc/datawarehouse/instances/[\w]+}],
        ['/gdc/datawarehouse/executions/{id}', %r{/gdc/datawarehouse/executions/[\w]+}],

        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[\w-]+/segments/[\w-]+/synchronizeClients/results/[\w]+/details/\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}',
         %r{/gdc/domains/[\w-]+/segments/[\w-]+/synchronizeClients/results/[\w]+}],
        ['/gdc/domains/{id}/segments/{segment}/', %r{/gdc/domains/[\w-]+/segments/[\w-]+/}],
        ['/gdc/domains/{id}/segments/{segment}', %r{/gdc/domains/[\w-]+/segments/[\w-]+}],
        ['/gdc/domains/{id}/clients?segment={segment}', %r{/gdc/domains/[\w-]+/clients\?segment=[\w-]+}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.title', %r{/gdc/domains/[\w-]+/clients/[\w-]+/settings/lcm.title}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.token', %r{/gdc/domains/[\w-]+/clients/[\w-]+/settings/lcm.token}],
        ['/gdc/domains/{id}/clients/{client_id}', %r{/gdc/domains/[\w-]+/clients/[\w-]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[\w-]+/provisionClientProjects/results/[\w]+/details/\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}', %r{/gdc/domains/[\w-]+/provisionClientProjects/results/[\w]+}],
        ['/gdc/domains/{id}/provisionClientProjects', %r{/gdc/domains/[\w-]+/provisionClientProjects}],
        ['/gdc/domains/{id}/updateClients', %r{/gdc/domains/[\w-]+/updateClients}],
        ['/gdc/domains/{id}/', %r{/gdc/domains/[\w-]+/}],

        ['/gdc/exporter/result/{id}/{id}', %r{/gdc/exporter/result/[\w]+/[\w]+}],

        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses/{process}',
         %r{/gdc/internal/lcm/domains/[\w-]+/dataproducts/[\w-]+/segments/[\w-]+/syncProcesses/[\w]+}],
        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses',
         %r{/gdc/internal/lcm/domains/[\w-]+/dataproducts/[\w-]+/segments/[\w-]+/syncProcesses}],

        ['/gdc/internal/projects/{id}/objects/setPermissions', %r{/gdc/internal/projects/[\w]+/objects/setPermissions}],

        ['/gdc/md/{id}/variables/item/{id}', %r{/gdc/md/[\w]+/variables/item/[\d]+}],
        ['/gdc/md/{id}/validate/task/{id}', %r{/gdc/md/[\w]+/validate/task/[\w]+}],
        ['/gdc/md/{id}/using2/{id}/{id}', %r{/gdc/md/[\w]+/using2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/using2/{id}', %r{/gdc/md/[\w]+/using2/[\d]+}],
        ['/gdc/md/{id}/userfilters?users={users}', %r{/gdc/md/[\w]+/userfilters\?users=[/\w]+}],
        ['/gdc/md/{id}/userfilters?count={count}&offset={offset}', %r{/gdc/md/[\w]+/userfilters\?count=[\d]+&offset=[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}', %r{/gdc/md/[\w]+/usedby2/[\d]+}],
        ['/gdc/md/{id}/tasks/{id}/status', %r{/gdc/md/[\w]+/tasks/[\w]+/status}],
        ['/gdc/md/{id}/obj/{id}/validElements', %r{/gdc/md/[\w]+/obj/[\d]+/validElements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}/elements', %r{/gdc/md/[\w]+/obj/[\d]+/elements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}', %r{/gdc/md/[\w]+/obj/[\d]+}],
        ['/gdc/md/{id}/etltask/{id}', %r{/gdc/md/[\w]+/etltask/[\w]+}],
        ['/gdc/md/{id}/dataResult/{id}', %r{/gdc/md/[\w]+/dataResult/[\d]+}],
        ['/gdc/md/{id}', %r{/gdc/md/[\w]+}],

        ['/gdc/projects/{id}/users/{id}/roles', %r{/gdc/projects/[\w]+/users/[\w]+/roles}],
        ['/gdc/projects/{id}/users/{id}/permissions', %r{/gdc/projects/[\w]+/users/[\w]+/permissions}],
        ['/gdc/projects/{id}/users', %r{/gdc/projects/[\w]+/users}],
        ['/gdc/projects/{id}/schedules/{id}/executions/{id}', %r{/gdc/projects/[\w]+/schedules/[\w]+/executions/[\w]+}],
        ['/gdc/projects/{id}/schedules/{id}', %r{/gdc/projects/[\w]+/schedules/[\w]+}],
        ['/gdc/projects/{id}/roles/{id}', %r{/gdc/projects/[\w]+/roles/[\d]+}],
        ['/gdc/projects/{id}/model/view/{id}', %r{/gdc/projects/[\w]+/model/view/[\w]+}],
        ['/gdc/projects/{id}/model/view', %r{/gdc/projects/[\w]+/model/view}],
        ['/gdc/projects/{id}/model/diff/{id}', %r{/gdc/projects/[\w]+/model/diff/[\w]+}],
        ['/gdc/projects/{id}/model/diff', %r{/gdc/projects/[\w]+/model/diff}],
        ['/gdc/projects/{id}/dataload/processes/{id}/executions/{id}', %r{/gdc/projects/[\w]+/dataload/processes/[\w-]+/executions/[\w-]+}],
        ['/gdc/projects/{id}/dataload/processes/{id}', %r{/gdc/projects/[\w]+/dataload/processes/[\w-]+}],
        ['/gdc/projects/{id}/', %r{/gdc/projects/[\w]+/}],
        ['/gdc/projects/{id}', %r{/gdc/projects/[\w]+}]
      ]
    end
  end
end
