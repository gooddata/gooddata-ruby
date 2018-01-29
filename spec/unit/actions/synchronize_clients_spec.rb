# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::SynchronizeClients do
  subject { GoodData::LCM2::SynchronizeClients }
  let(:failure_details) { '/link/to/details' }
  let(:failed_count) { 42 }
  let(:sync_failed_response_body) do
    {
      "synchronizationResult" => {
        "successfulClients" => {
          "count" => 0
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
end
