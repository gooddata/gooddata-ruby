# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

shared_examples 'a computed attributes synchronizer' do
  it 'it synchronizes computed attributes' do
    expect(project).to receive(:execute_maql).with('expected_maql')
    result = subject.class.call(converted_params)
    expect(result).not_to be_empty
  end
end

describe GoodData::LCM2::SynchronizeComputedAttributes do
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:logger) { double(Logger) }
  let(:project) { double(GoodData::Project) }
  let(:synchronize) do
    [{ from: 'foo', to: [{ pid: 'pid', ca_scripts: { 'maqlDdlChunks' => ['expected_maql'] } }] }]
  end
  let(:basic_params) do
    {
      gdc_gd_client: gdc_gd_client,
      development_client: gdc_gd_client,
      synchronize: synchronize,
      gdc_logger: logger
    }
  end
  let(:converted_params) do
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:projects).and_return(project)
    allow(project).to receive(:title)
    allow(project).to receive(:pid)
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
  end

  context 'when include_computed_attributes is not specified' do
    let(:params) { basic_params }
    it_behaves_like 'a computed attributes synchronizer'
  end

  context 'when include_computed_attributes is true' do
    let(:params) { basic_params.merge(include_computed_attributes: 'true') }
    it_behaves_like 'a computed attributes synchronizer'
  end

  context 'when include_computed_attributes is false' do
    let(:params) { basic_params.merge(include_computed_attributes: 'false') }
    it 'it does not synchronize computed attributes' do
      result = subject.class.call(converted_params)
      expect(result).to be_empty
    end
  end

  context 'when process get errors' do
    let(:params) {
      params = basic_params.merge({
            collect_synced_status: true,
            sync_failed_list: {
              project_client_mappings: {},
              client_project_mappings: {},
              failed_detailed_projects: [],
              failed_projects: [],
              failed_clients: [],
              failed_segments: []
            }
          })
      GoodData::LCM2.convert_to_smart_hash(params)
    }

    it 'it process warning status' do
      allow(project).to receive(:execute_maql).and_raise('Error occurred when executing MAQL')
      allow(project).to receive(:pid).and_return('pid')

      # Action get errors but still continue process
      result = subject.class.call(params)
      failed_detailed_projects = params.sync_failed_list.failed_detailed_projects

      expect(result.size).to eq(1)
      expect(result[0][:from]).to eq('foo')
      expect(result[0][:to]).to eq('pid')
      expect(result[0][:status]).to eq('failed')
      expect(failed_detailed_projects.size).to eq(1)
      expect(failed_detailed_projects[0][:project_id]).to eq('pid')
      expect(failed_detailed_projects[0][:message]).to include('Error occurred when executing MAQL')
    end
  end
end
