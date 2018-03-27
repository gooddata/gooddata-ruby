# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/rest/phmap'

PlaceholderExample = Struct.new(:name, :title, :mapped)

describe GoodData::Rest::Connection do
  [
    PlaceholderExample.new('execute', '/gdc/projects/uif55z7zg9zunnsffsqu6nzyg38j20qg/execute', '/gdc/projects/{id}/execute'),

    PlaceholderExample.new('outputStage', '/gdc/dataload/projects/uif55z7zg9zunnsffsqu6nzyg38j20qg/outputStage', '/gdc/dataload/projects/{id}/outputStage'),

    PlaceholderExample.new('datawarehouse instance', '/gdc/datawarehouse/instances/c90ef89f07978760523dd409165c71f3', '/gdc/datawarehouse/instances/{id}'),
    PlaceholderExample.new('datawarehouse execution', '/gdc/datawarehouse/executions/exec123', '/gdc/datawarehouse/executions/{id}'),

    PlaceholderExample.new('dataproduct client segment', '/gdc/domains/stg2-lcm-prod/dataproducts/MY-DP/clients?segment=MY-SEG4',
                           '/gdc/domains/{id}/dataproducts/{data_product}/clients?segment={segment}'),
    PlaceholderExample.new('dataproduct client', '/gdc/domains/MY_DOMAIN3/dataproducts/4_7-prod/clients/some-client1',
                           '/gdc/domains/{id}/dataproducts/{data_product}/clients/{client}'),
    PlaceholderExample.new('dataproduct clients', '/gdc/domains/D_-3/dataproducts/DP_1-/clients', '/gdc/domains/{id}/dataproducts/{data_product}/clients'),

    PlaceholderExample.new('synchronizeClients result details', '/gdc/domains/d2/dataproducts/dp-6/segments/seg_1/synchronizeClients/results/_-res8/details?offset=0&limit=1000',
                           '/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}'),
    PlaceholderExample.new('synchronizeClients result', '/gdc/domains/D/dataproducts/DP/segments/SEG/synchronizeClients/results/RES',
                           '/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}/synchronizeClients/results/{result}'),
    PlaceholderExample.new('dataproduct segment', '/gdc/domains/D/dataproducts/DP/segments/SEG', '/gdc/domains/{id}/dataproducts/{data_product}/segments/{segment}'),
    PlaceholderExample.new('dataproduct segments', '/gdc/domains/D/dataproducts/DP/segments', '/gdc/domains/{id}/dataproducts/{data_product}/segments'),

    PlaceholderExample.new('provisionClientProjects result details', '/gdc/domains/D/dataproducts/DP/provisionClientProjects/results/RES/details?offset=7&limit=50',
                           '/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}'),
    PlaceholderExample.new('provisionClientProjects result', '/gdc/domains/D/dataproducts/DP/provisionClientProjects/results/RES',
                           '/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects/results/{result}'),
    PlaceholderExample.new('provisionClientProjects', '/gdc/domains/D/dataproducts/DP/provisionClientProjects',
                           '/gdc/domains/{id}/dataproducts/{data_product}/provisionClientProjects'),
    PlaceholderExample.new('updateClients delet extra', '/gdc/domains/D/dataproducts/DP/updateClients?deleteExtraInSegments=SEG',
                           '/gdc/domains/{id}/dataproducts/{data_product}/updateClients?deleteExtraInSegments={segments}'),
    PlaceholderExample.new('updateClients', '/gdc/domains/D/dataproducts/DP/updateClients', '/gdc/domains/{id}/dataproducts/{data_product}/updateClients'),

    PlaceholderExample.new('domain dataproducts', '/gdc/domains/D/dataproducts/DP', '/gdc/domains/{id}/dataproducts/{data_product}'),
    PlaceholderExample.new('domain dataproducts', '/gdc/domains/D/dataproducts', '/gdc/domains/{id}/dataproducts'),

    PlaceholderExample.new('segment synchronizeClients result details', '/gdc/domains/D/segments/SEG/synchronizeClients/results/RES/details?offset=0&limit=100',
                           '/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}/details?offset={offset}&limit={limit}'),
    PlaceholderExample.new('segment synchronizeClients result', '/gdc/domains/D/segments/SEG/synchronizeClients/results/RES',
                           '/gdc/domains/{id}/segments/{segment}/synchronizeClients/results/{result}'),
    PlaceholderExample.new('domain segment', '/gdc/domains/D/segments/SEG/', '/gdc/domains/{id}/segments/{segment}/'),
    PlaceholderExample.new('domain segment', '/gdc/domains/D/segments/SEG', '/gdc/domains/{id}/segments/{segment}'),

    PlaceholderExample.new('domain client segment', '/gdc/domains/D/clients?segment=SEG', '/gdc/domains/{id}/clients?segment={segment}'),
    PlaceholderExample.new('client settings title', '/gdc/domains/D/clients/C/settings/lcm.title', '/gdc/domains/{id}/clients/{client_id}/settings/lcm.title'),
    PlaceholderExample.new('client settings token', '/gdc/domains/D/clients/C/settings/lcm.token', '/gdc/domains/{id}/clients/{client_id}/settings/lcm.token'),
    PlaceholderExample.new('domain client', '/gdc/domains/D/clients/C', '/gdc/domains/{id}/clients/{client_id}'),
    PlaceholderExample.new('domain provisionClientProjects result details', '/gdc/domains/D/provisionClientProjects/results/R/details?offset=0&limit=100',
                           '/gdc/domains/{id}/provisionClientProjects/results/{result}/details?offset={offset}&limit={limit}'),
    PlaceholderExample.new('domain provisionClientProjects result', '/gdc/domains/D/provisionClientProjects/results/R',
                           '/gdc/domains/{id}/provisionClientProjects/results/{result}'),
    PlaceholderExample.new('domain provisionClientProjects', '/gdc/domains/D/provisionClientProjects', '/gdc/domains/{id}/provisionClientProjects'),
    PlaceholderExample.new('domain updateClients', '/gdc/domains/D/updateClients', '/gdc/domains/{id}/updateClients'),
    PlaceholderExample.new('domain', '/gdc/domains/D/', '/gdc/domains/{id}/'),

    PlaceholderExample.new('exporter result', '/gdc/exporter/result/a23f/c56', '/gdc/exporter/result/{id}/{id}'),

    PlaceholderExample.new('syncProcesses task', '/gdc/internal/lcm/domains/D/dataproducts/DP/segments/SEG/syncProcesses/P',
                           '/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses/{process}'),
    PlaceholderExample.new('syncProcesses', '/gdc/internal/lcm/domains/D/dataproducts/DP/segments/SEG/syncProcesses',
                           '/gdc/internal/lcm/domains/{id}/dataproducts/{data_product}/segments/{segment}/syncProcesses'),

    PlaceholderExample.new('setPermissions', '/gdc/internal/projects/PID/objects/setPermissions', '/gdc/internal/projects/{id}/objects/setPermissions'),

    PlaceholderExample.new('md variable', '/gdc/md/PID/variables/item/54', '/gdc/md/{id}/variables/item/{id}'),
    PlaceholderExample.new('md validate task', '/gdc/md/PID/validate/task/some-task56', '/gdc/md/{id}/validate/task/{id}'),
    PlaceholderExample.new('md using', '/gdc/md/PID/using2/456/980', '/gdc/md/{id}/using2/{id}/{id}'),
    PlaceholderExample.new('md using', '/gdc/md/PID/using2/456', '/gdc/md/{id}/using2/{id}'),
    PlaceholderExample.new('md userfilters user', '/gdc/md/PID/userfilters?users=/gdc/account/profile/rubydev+admin@goo', '/gdc/md/{id}/userfilters?users={users}'),
    PlaceholderExample.new('md userfilters', '/gdc/md/PID/userfilters?count=1&offset=5', '/gdc/md/{id}/userfilters?count={count}&offset={offset}'),
    PlaceholderExample.new('md usedby', '/gdc/md/PID/usedby2/4/5', '/gdc/md/{id}/usedby2/{id}/{id}'),
    PlaceholderExample.new('md usedby', '/gdc/md/PID/usedby2/4', '/gdc/md/{id}/usedby2/{id}'),
    PlaceholderExample.new('md task status', '/gdc/md/PID/tasks/567/status', '/gdc/md/{id}/tasks/{id}/status'),
    PlaceholderExample.new('md validElements', '/gdc/md/PID/obj/876/validElements', '/gdc/md/{id}/obj/{id}/validElements'),
    PlaceholderExample.new('md elements', '/gdc/md/PID/obj/876/elements', '/gdc/md/{id}/obj/{id}/elements'),
    PlaceholderExample.new('md obj', '/gdc/md/PID/obj/876', '/gdc/md/{id}/obj/{id}'),
    PlaceholderExample.new('md etltaks', '/gdc/md/PID/etltask/567', '/gdc/md/{id}/etltask/{id}'),
    PlaceholderExample.new('md dataResult', '/gdc/md/PID/dataResult/666', '/gdc/md/{id}/dataResult/{id}'),
    PlaceholderExample.new('md', '/gdc/md/PID', '/gdc/md/{id}'),

    PlaceholderExample.new('project user roles', '/gdc/projects/PID/users/UID/roles', '/gdc/projects/{id}/users/{id}/roles'),
    PlaceholderExample.new('project user permissions', '/gdc/projects/PID/users/UID/permissions', '/gdc/projects/{id}/users/{id}/permissions'),
    PlaceholderExample.new('project users', '/gdc/projects/PID/users', '/gdc/projects/{id}/users'),
    PlaceholderExample.new('schedule execution', '/gdc/projects/PID/schedules/SCHED/executions/EX', '/gdc/projects/{id}/schedules/{id}/executions/{id}'),
    PlaceholderExample.new('schedule', '/gdc/projects/PID/schedules/SCHED', '/gdc/projects/{id}/schedules/{id}'),
    PlaceholderExample.new('project role', '/gdc/projects/PID/roles/555', '/gdc/projects/{id}/roles/{id}'),
    PlaceholderExample.new('model view view', '/gdc/projects/PID/model/view/VIEW', '/gdc/projects/{id}/model/view/{id}'),
    PlaceholderExample.new('model view', '/gdc/projects/PID/model/view', '/gdc/projects/{id}/model/view'),
    PlaceholderExample.new('model diff diff', '/gdc/projects/PID/model/diff/DIFF', '/gdc/projects/{id}/model/diff/{id}'),
    PlaceholderExample.new('model diff', '/gdc/projects/PID/model/diff', '/gdc/projects/{id}/model/diff'),
    PlaceholderExample.new('dataload metadata', '/gdc/projects/PID/dataload/metadata/PID', '/gdc/projects/{id}/dataload/metadata/{project}'),
    PlaceholderExample.new('dataload execution', '/gdc/projects/PID/dataload/processes/PRID/executions/EX', '/gdc/projects/{id}/dataload/processes/{id}/executions/{id}'),
    PlaceholderExample.new('dataload process', '/gdc/projects/PID/dataload/processes/PRID', '/gdc/projects/{id}/dataload/processes/{id}'),
    PlaceholderExample.new('project', '/gdc/projects/PID/', '/gdc/projects/{id}/'),
    PlaceholderExample.new('project', '/gdc/projects/PID', '/gdc/projects/{id}'),

    PlaceholderExample.new('userGroup', '/gdc/userGroups/GID', '/gdc/userGroups/{id}'),

    PlaceholderExample.new('profile', '/gdc/account/profile/UID', '/gdc/account/profile/{id}'),
    PlaceholderExample.new('login', '/gdc/account/login/UID', '/gdc/account/login/{id}'),
    PlaceholderExample.new('domain user', '/gdc/account/domains/D/users?login=rubydev+admin@gooddata.com', '/gdc/account/domains/{id}/users?login={login}'),
    PlaceholderExample.new('account domain', '/gdc/account/domains/D', '/gdc/account/domains/{id}')
  ].each do |example|
    it "should map placeholders in #{example.name} API" do
      expect(GoodData::Rest::Connection.map_placeholders(example.title)).to eq(example.mapped)
    end
  end
end
