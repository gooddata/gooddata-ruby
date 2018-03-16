# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

shared_examples 'a computed attributes synchronizer' do
  it 'diffs LDM with computed attributes' do
    expect(project).to receive(:blueprint).with(include_ca: true)
    subject.class.call(converted_params)
  end
end

describe GoodData::LCM2::SynchronizeLdm do
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:logger) { double(Logger) }
  let(:project) { double(GoodData::Project) }
  let(:target_project) { double(GoodData::Project) }
  let(:synchronize) do
    [{ from: 'from_pid', to: [{ pid: 'to_pid' }] }]
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
    allow(gdc_gd_client).to receive(:projects)
      .with('from_pid')
      .and_return(project)
    allow(gdc_gd_client).to receive(:projects)
      .with('to_pid')
      .and_return(target_project)
    allow(project).to receive(:title)
    allow(project).to receive(:pid)
    allow(project).to receive(:blueprint)
    allow(logger).to receive(:info)
    allow(target_project).to receive(:title)
    allow(target_project).to receive(:update_from_blueprint)
  end

  context 'when include_computed_attributes is true' do
    let(:params) { basic_params.merge(include_computed_attributes: 'true') }
    it_behaves_like 'a computed attributes synchronizer'
  end

  context 'when include_computed_attributes is false' do
    let(:params) { basic_params.merge(include_computed_attributes: 'false') }
    it 'diffs LDM without computed attributes' do
      expect(project).to receive(:blueprint).with(include_ca: false)
      subject.class.call(converted_params)
    end
  end

  context 'when exclude_fact_rule is true' do
    let(:params) { basic_params.merge(exclude_fact_rule: 'true') }
    it 'calls update_from_blueprint with exclude_fact_rule option' do
      expect(target_project).to receive(:update_from_blueprint)
        .with(any_args, hash_including(exclude_fact_rule: true))
      subject.class.call(converted_params)
    end
  end
end
