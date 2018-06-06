# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  module Rest
    class Connection
      def self.map_placeholders(title)
        PH_MAP.each do |pm|
          break if title.gsub!(pm[1], pm[0])
        end
        title
      end

      # PH_MAP for wildcarding of URLs in reports
      PH_MAP = [
        ['/gdc/projects/{id}/execute', %r{/gdc/projects/[^\/]+/execute}],

        ['/gdc/dataload/projects/{id}/outputStage', %r{/gdc/dataload/projects/[^\/]+/outputStage}],

        ['/gdc/datawarehouse/instances/{id}', %r{/gdc/datawarehouse/instances/[^\/]+}],
        ['/gdc/datawarehouse/executions/{id}', %r{/gdc/datawarehouse/executions/[^\/]+}],

        # domain dataproducts' clients
        ['/gdc/domains/{id}/dataproducts/{data_product}/clients?segment={segment}',
         %r{\/gdc\/domains\/[^\/]+\/dataproducts\/[^\/]+\/clients\?.*segment=[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/clients/{client}', %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/clients/[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/clients', %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/clients}],

        # domain dataproducts' segments
        ['/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/segments/[^\/]+/synchronizeClients/results/[^\/]+/details\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}/synchronizeClients/results/{result}',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/segments/[^\/]+/synchronizeClients/results/[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}', %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/segments/[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/segments', %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/segments}],

        # domain dataproducts' provision & update
        ['/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/provisionClientProjects/results/[^\/]+/details\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects/results/{result}',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/provisionClientProjects/results/[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/provisionClientProjects}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/updateClients?deleteExtraInSegments={segments}',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/updateClients\?deleteExtraInSegments=[^\/]+}],
        ['/gdc/domains/{id}/dataproducts/{data_product}/updateClients',
         %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+/updateClients}],

        # domain dataproduct
        ['/gdc/domains/{id}/dataproducts/{data_product}', %r{/gdc/domains/[^\/]+/dataproducts/[^\/]+}],
        ['/gdc/domains/{id}/dataproducts', %r{/gdc/domains/[^\/]+/dataproducts}],

        # domain segments
        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[^\/]+/segments/[^\/]+/synchronizeClients/results/[^\/]+/details\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}',
         %r{/gdc/domains/[^\/]+/segments/[^\/]+/synchronizeClients/results/[^\/]+}],
        ['/gdc/domains/{id}/segments/{segment}/', %r{/gdc/domains/[^\/]+/segments/[^\/]+/}],
        ['/gdc/domains/{id}/segments/{segment}', %r{/gdc/domains/[^\/]+/segments/[^\/]+}],

        # domain clients
        ['/gdc/domains/{id}/clients?segment={segment}', %r{/gdc/domains/[^\/]+/clients\?segment=[^\/]+}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.title', %r{/gdc/domains/[^\/]+/clients/[^\/]+/settings/lcm.title}],
        ['/gdc/domains/{id}/clients/{client_id}/settings/lcm.token', %r{/gdc/domains/[^\/]+/clients/[^\/]+/settings/lcm.token}],
        ['/gdc/domains/{id}/clients/{client_id}', %r{/gdc/domains/[^\/]+/clients/[^\/]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}',
         %r{/gdc/domains/[^\/]+/provisionClientProjects/results/[^\/]+/details\?offset=[\d]+&limit=[\d]+}],
        ['/gdc/domains/{id}/provisionClientProjects/results/{result}', %r{/gdc/domains/[^\/]+/provisionClientProjects/results/[^\/]+}],
        ['/gdc/domains/{id}/provisionClientProjects', %r{/gdc/domains/[^\/]+/provisionClientProjects}],
        ['/gdc/domains/{id}/updateClients', %r{/gdc/domains/[^\/]+/updateClients}],
        ['/gdc/domains/{id}/', %r{/gdc/domains/[^\/]+/}],

        ['/gdc/exporter/result/{id}/{id}', %r{/gdc/exporter/result/[^\/]+/[^\/]+}],

        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses/{process}',
         %r{/gdc/internal/lcm/domains/[^\/]+/dataproducts/[^\/]+/segments/[^\/]+/syncProcesses/[^\/]+}],
        ['/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses',
         %r{/gdc/internal/lcm/domains/[^\/]+/dataproducts/[^\/]+/segments/[^\/]+/syncProcesses}],

        ['/gdc/internal/projects/{id}/objects/setPermissions', %r{/gdc/internal/projects/[^\/]+/objects/setPermissions}],
        ['/gdc/internal/projects/{id}/roles', %r{/gdc/internal/projects/[^\/]+/roles}],

        ['/gdc/md/{id}/variables/item/{id}', %r{/gdc/md/[^\/]+/variables/item/[\d]+}],
        ['/gdc/md/{id}/validate/task/{id}', %r{/gdc/md/[^\/]+/validate/task/[^\/]+}],
        ['/gdc/md/{id}/using2/{id}/{id}', %r{/gdc/md/[^\/]+/using2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/using2/{id}', %r{/gdc/md/[^\/]+/using2/[\d]+}],
        ['/gdc/md/{id}/userfilters?users={users}', %r{\/gdc\/md\/[^\/]+\/userfilters\?users=[\/\w+@.]+}],
        ['/gdc/md/{id}/userfilters?count={count}&offset={offset}', %r{/gdc/md/[^\/]+/userfilters\?count=[\d]+&offset=[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}/{id}', %r{/gdc/md/[^\/]+/usedby2/[\d]+/[\d]+}],
        ['/gdc/md/{id}/usedby2/{id}', %r{/gdc/md/[^\/]+/usedby2/[\d]+}],
        ['/gdc/md/{id}/tasks/{id}/status', %r{/gdc/md/[^\/]+/tasks/[^\/]+/status}],
        ['/gdc/md/{id}/obj/{id}/validElements', %r{/gdc/md/[^\/]+/obj/[\d]+/validElements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}/elements', %r{/gdc/md/[^\/]+/obj/[\d]+/elements(/)?(\?.*)?}],
        ['/gdc/md/{id}/obj/{id}', %r{/gdc/md/[^\/]+/obj/[\d]+}],
        ['/gdc/md/{id}/etltask/{id}', %r{/gdc/md/[^\/]+/etltask/[^\/]+}],
        ['/gdc/md/{id}/dataResult/{id}', %r{/gdc/md/[^\/]+/dataResult/[\d]+}],
        ['/gdc/md/{id}', %r{/gdc/md/[^\/]+}],

        ['/gdc/projects/{id}/users/{id}/roles', %r{/gdc/projects/[^\/]+/users/[^\/]+/roles}],
        ['/gdc/projects/{id}/users/{id}/permissions', %r{/gdc/projects/[^\/]+/users/[^\/]+/permissions}],
        ['/gdc/projects/{id}/users', %r{/gdc/projects/[^\/]+/users}],
        ['/gdc/projects/{id}/schedules/{id}/executions/{id}', %r{/gdc/projects/[^\/]+/schedules/[^\/]+/executions/[^\/]+}],
        ['/gdc/projects/{id}/schedules/{id}', %r{/gdc/projects/[^\/]+/schedules/[^\/]+}],
        ['/gdc/projects/{id}/roles/{id}', %r{/gdc/projects/[^\/]+/roles/[\d]+}],
        ['/gdc/projects/{id}/model/view/{id}', %r{/gdc/projects/[^\/]+/model/view/[^\/]+}],
        ['/gdc/projects/{id}/model/view', %r{/gdc/projects/[^\/]+/model/view}],
        ['/gdc/projects/{id}/model/diff/{id}', %r{/gdc/projects/[^\/]+/model/diff/[^\/]+}],
        ['/gdc/projects/{id}/model/diff', %r{/gdc/projects/[^\/]+/model/diff}],
        ['/gdc/projects/{id}/dataload/metadata/{project}', %r{/gdc/projects/[^\/]+/dataload/metadata/[^\/]+}],
        ['/gdc/projects/{id}/dataload/processes/{id}/executions/{id}', %r{/gdc/projects/[^\/]+/dataload/processes/[^\/]+/executions/[^\/]+}],
        ['/gdc/projects/{id}/dataload/processes/{id}', %r{/gdc/projects/[^\/]+/dataload/processes/[^\/]+}],
        ['/gdc/projects/{id}/', %r{/gdc/projects/[^\/]+/}],
        ['/gdc/projects/{id}', %r{/gdc/projects/[^\/]+}],

        ['/gdc/userGroups/{id}', %r{/gdc/userGroups/[^\/]+}],

        ['/gdc/account/profile/{id}', %r{/gdc/account/profile/[^\/]+}],
        ['/gdc/account/login/{id}', %r{/gdc/account/login/[^\/]+}],
        ['/gdc/account/domains/{id}/users?login={login}', %r{/gdc/account/domains/[^\/]+/users\?login=[^&$]+}],
        ['/gdc/account/domains/{id}', %r{/gdc/account/domains/[^\/]+}]
      ]
    end
  end
end
