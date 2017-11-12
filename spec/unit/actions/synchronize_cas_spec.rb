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
    [{ from: 'foo', to: [{ ca_scripts: { 'maqlDdlChunks' => ['expected_maql'] } }] }]
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
end
