# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::SynchronizeClients do
  subject { GoodData::LCM2::SynchronizeClients }
  let(:failure_details) { '/link/to/details' }
  let(:success_count) { 50 }
  let(:failed_count) { 42 }
  let(:sync_failed_response_body) do
    {
      "synchronizationResult" => {
        "successfulClients" => {
          "count" => success_count
        },
        "failedClients" => {
          "count" => failed_count
        },
        "links" => {
          "details" => failure_details
        }
      }
    }
  end
  let(:sync_clients_detail_result) do
    {
      "items" => [
        {
          "status" => "error",
          "id" => "pid",
          "error" => {
            "message" => "Error sync dataset",
            "parameters" => "expected_error_sync_ds"
          }
        }
      ]
    }
  end

  let(:sync_failed_response) { double(RestClient::Response) }
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:logger) { double(Logger) }
  let(:organization_name) { 'big-boss-group' }
  let(:organization) { double(GoodData::Domain) }
  let(:segment) { double(GoodData::Segment) }
  let(:ads_client) { double(GoodData::DataWarehouse) }
  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      development_client: gdc_gd_client,
      organization: organization_name,
      segments: [segment],
      release_table_name: 'LCM_RELEASE',
      ads_client: ads_client,
      gdc_logger: logger
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:domain).with(organization_name)
                                            .and_return(organization)
    allow(organization).to receive(:segments).and_return([segment])
    allow(segment).to receive(:segment_id).and_return('id_of_my_segment')
    allow(gdc_gd_client).to receive(:projects)
    allow(ads_client).to receive(:execute_select).and_return([{}])
    allow(segment).to receive(:master_project=)
    allow(segment).to receive(:save)
    allow(sync_failed_response)
      .to receive(:json).and_return(sync_failed_response_body)
  end

  context 'when synchronizing client fails' do
    before do
      allow(segment)
        .to receive(:synchronize_clients).and_return(sync_failed_response)
    end
    it 'fails with a clear error message' do
      expected_error_message = "#{failed_count} clients failed to " \
                               "synchronize. Details: #{failure_details}"
      expect { subject.call(params) }.to raise_error(expected_error_message)
    end
  end

  context 'when synchronizing client get errors' do
    before do
      detail_items = []
      detail_items << {
        status: 'error',
        id: 'pid',
        error: {
          message: 'Error sync dataset',
          parameters: 'expected_error_sync_ds'
        }
      }

      allow(segment).to receive(:synchronize_clients)
                                         .and_return(sync_failed_response)
      allow(sync_failed_response).to receive(:details)
                                         .and_return(sync_clients_detail_result)
      allow(sync_clients_detail_result).to receive(:items)
                                         .and_return(detail_items)
      allow(segment).to receive(:id).and_return('id_of_my_segment')
      allow(logger).to receive(:warn)
    end

    let(:warning_params) {
      warning_params = params.merge({
                                      collect_synced_status: true,
                                      sync_failed_list: {
                                        failed_detailed_projects: [],
                                        failed_projects: [],
                                        failed_clients: [],
                                        failed_segments: []
                                      }
                                  })
      GoodData::LCM2.convert_to_smart_hash(warning_params)
    }

    it 'it processes warning status' do
      # Action get errors but still continue process
      result = subject.call(warning_params)
      expect(result.size).to eq(1)
      expect(result[0][:segment]).to eq('id_of_my_segment')
      expect(result[0][:successful_count]).to eq(50)
    end
  end
end

describe '.remove old master workspace' do
  let(:segment_id) { 'id_of_my_segment' }
  let(:number_of_deleted_projects) { 2 }
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:logger) { double(Logger) }
  let(:ads_client) { double(GoodData::DataWarehouse) }
  let(:project_1) { double(GoodData::Project) }
  let(:project_2) { double(GoodData::Project) }
  let(:project_3) { double(GoodData::Project) }
  let(:master_projects) do
    [
        { master_project_id: 'foo', version: 1, segment_id: 'id_of_my_segment' },
        { master_project_id: 'bar', version: 2, segment_id: 'id_of_my_segment' },
        { master_project_id: 'baz', version: 3, segment_id: 'id_of_my_segment' },
        { master_project_id: 'qux', version: 4, segment_id: 'id_of_my_segment' }
    ]
  end
  let(:master_project_id_1) { 'foo' }
  let(:master_project_id_2) { 'bar' }
  let(:master_project_id_3) { 'baz' }
  let(:project_title_1) { 'title 1' }
  let(:project_title_2) { 'title 2' }
  let(:project_title_3) { 'title 3' }
  let(:params) do
    params = {
        gdc_gd_client: gdc_gd_client,
        release_table_name: 'LCM_RELEASE',
        ads_client: ads_client,
        gdc_logger: logger
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  subject { GoodData::LCM2::SynchronizeClients.remove_multiple_workspace(params, segment_id, master_projects, number_of_deleted_projects) }

  before do
    allow(project_1).to receive(:delete)
    allow(project_1).to receive(:deleted?).and_return(false)
    allow(gdc_gd_client).to receive(:projects)
                                .with(master_project_id_1)
                                .and_return(project_1)
    allow(project_1).to receive(:pid).and_return(master_project_id_1)
    allow(project_1).to receive(:title).and_return(project_title_1)
    allow(project_1).to receive(:state).and_return('enabled')

    allow(gdc_gd_client).to receive(:projects)
                                .with(master_project_id_2)
                                .and_return(project_2)
    allow(project_2).to receive(:pid).and_return(master_project_id_2)
    allow(project_2).to receive(:title).and_return(project_title_2)
    allow(project_2).to receive(:state).and_return('deleted')

    allow(gdc_gd_client).to receive(:projects)
                                .with(master_project_id_3)
                                .and_return(project_3)
    allow(project_3).to receive(:pid).and_return(master_project_id_3)
    allow(project_3).to receive(:title).and_return(project_title_3)
    allow(project_3).to receive(:state).and_return('deleted')
  end

  context 'when remove some old master workspaces' do
    let(:removal_master_project_ids) { ['foo', 'bar'] }
    it 'returns deleted master workspaces' do
      expect(subject).to eq(removal_master_project_ids)
    end
  end
end
