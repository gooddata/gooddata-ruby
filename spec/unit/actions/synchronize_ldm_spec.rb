# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

shared_examples 'a computed attributes synchronizer' do
  it 'diffs LDM with computed attributes' do
    expect(project).to receive(:blueprint).with(include_ca: true)
    subject
  end
end

describe GoodData::LCM2::SynchronizeLdm do
  subject do
    GoodData::LCM2.run_action(
      GoodData::LCM2::SynchronizeLdm,
      converted_params
    )
  end
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:logger) { double(Logger) }
  let(:project) { double(GoodData::Project) }
  let(:target_project) { double(GoodData::Project) }
  let(:synchronize) do
    [{ from: 'from_pid', to: [{ pid: 'to_pid' }] }]
  end
  let(:synchronize_ldm) { nil }
  let(:basic_params) do
    {
      gdc_gd_client: gdc_gd_client,
      development_client: gdc_gd_client,
      synchronize: synchronize,
      gdc_logger: logger,
      synchronize_ldm: synchronize_ldm
    }
  end
  let(:params) { basic_params }
  let(:converted_params) { GoodData::LCM2.convert_to_smart_hash(params) }

  before do
    allow(gdc_gd_client).to receive(:projects)
      .with('from_pid')
      .and_return(project)
    allow(gdc_gd_client).to receive(:projects)
      .with('to_pid')
      .and_return(target_project)
    allow(gdc_gd_client).to receive(:class) { GoodData::Rest::Client }
    allow(project).to receive(:title)
    allow(project).to receive(:pid)
    allow(project).to receive(:blueprint)
    allow(logger).to receive(:info)
    allow(logger).to receive(:class) { Logger }
    allow(target_project).to receive(:title)
    allow(target_project).to receive(:update_from_blueprint)
  end

  it 'updates ldm of the client' do
    expect(target_project).to receive(:update_from_blueprint)
      .once
      .with(any_args, :update_preference => nil,
                      :exclude_fact_rule => false,
                      :execute_ca_scripts => false,
                      :maql_diff => nil)
    subject
  end

  it 'sets synchronize param' do
    expect(subject[:params][:synchronize]).to eq(
      [{ from: 'from_pid', to: [{ pid: 'to_pid', ca_scripts: nil }] }]
    )
  end

  it 'sets result' do
    expect(subject[:results]).to eq(
      [{ from: 'from_pid', to: 'to_pid', status: 'ok' }]
    )
  end

  context 'when include_computed_attributes is true' do
    let(:params) { basic_params.merge(include_computed_attributes: 'true') }
    it_behaves_like 'a computed attributes synchronizer'
  end

  context 'when include_computed_attributes is false' do
    let(:params) { basic_params.merge(include_computed_attributes: 'false') }
    it 'diffs LDM without computed attributes' do
      expect(project).to receive(:blueprint).with(include_ca: false)
      subject
    end
  end

  context 'when exclude_fact_rule is true' do
    let(:params) { basic_params.merge(exclude_fact_rule: 'true') }
    it 'calls update_from_blueprint with exclude_fact_rule option' do
      expect(target_project).to receive(:update_from_blueprint)
        .with(any_args, hash_including(exclude_fact_rule: true))
      subject
    end
  end

  context 'when diff_ldm_against specified' do
    let(:synchronize_ldm) { 'diff_against_master_with_fallback' }
    let(:diff_against) { double(GoodData::Project) }
    let(:maql_diff) { 'awesome diff' }
    let(:synchronize) do
      [{ from: 'from_pid', to: [{ pid: 'to_pid' }], diff_ldm_against: diff_against }]
    end

    before do
      allow(diff_against).to receive(:maql_diff)
        .and_return(maql_diff)
    end

    it 'applies MAQL diff of that project to clients' do
      expect(target_project).to receive(:update_from_blueprint)
        .with(any_args, hash_including(maql_diff: maql_diff))
      subject
    end

    context 'when synchronize_ldm set to diff_against_clients' do
      let(:synchronize_ldm) { 'diff_against_clients' }
      it 'diffs against each client separately' do
        expect(target_project).to receive(:update_from_blueprint)
          .once
          .with(any_args, hash_including(maql_diff: nil))
        subject
      end
    end

    context 'when client has conflicting ldm' do
      before do
        allow(target_project).to receive(:update_from_blueprint)
          .with(any_args, hash_including(maql_diff: maql_diff))
          .and_raise(GoodData::MaqlExecutionError, 'Kaboom! Conflicting LDM!')
      end

      it 'falls back to diffing against clients' do
        expect(target_project).to receive(:update_from_blueprint)
          .with(any_args, hash_excluding(:maql_diff))
        subject
      end

      context 'when synchronize_ldm is diff_against_master' do
        let(:synchronize_ldm) { 'diff_against_master' }
        it 'does not fall back to diff against client' do
          expect(target_project).not_to receive(:update_from_blueprint)
            .once
            .with(any_args, hash_including(maql_diff: maql_diff))

          expect { subject }.to raise_error
        end
      end
    end
  end
end
