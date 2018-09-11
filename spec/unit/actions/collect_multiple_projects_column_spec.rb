# encoding: UTF-8
#
# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

describe GoodData::LCM2::CollectMultipleProjectsColumn do
  let(:client) { double(:client) }
  let(:domain) { double(:domain) }
  let(:gdc_logger) { double(:gdc_logger) }
  let(:params_stub) do
    {
      domain: domain,
      gdc_gd_client: client,
      gdc_logger: gdc_logger
    }
  end

  before do
    allow(client).to receive(:domain) { domain }
    allow(gdc_logger).to receive(:info)
  end

  context 'when passed a multiple projects column from input' do
    let(:column) { 'my_id' }
    it 'resolves it from input' do
      result = subject.class.call GoodData::LCM2.convert_to_smart_hash(params_stub.merge(multiple_projects_column: column))
      expect(result[:params][:multiple_projects_column]).to eq column
    end
  end

  context 'when not passed a multiple projects column' do
    expected_results = {
      'sync_multiple_projects_based_on_pid' => 'project_id',
      'sync_multiple_projects_based_on_custom_id' => 'client_id',
      'sync_domain_client_workspaces' => 'client_id'
    }
    it 'resolves the correct column for the sync mode' do
      expected_results.each do |mode, col|
        result = subject.class.call GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: mode))
        expect(result[:params][:multiple_projects_column]).to eq col
      end
    end
  end
end
