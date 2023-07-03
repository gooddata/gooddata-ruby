# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'
require_relative '../support/mock_factory'

describe GoodData::LCM2::SynchronizeETLsInSegment do
  let(:gdc_gd_client) { double_with_class(GoodData::Rest::Client) }
  let(:logger) { double_with_class(Logger) }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:project) { double('project') }
  let(:result) { { syncedResult: {} } }
  let(:client_id) { 'foo_client' }
  let(:data_product) { double_with_class(GoodData::DataProduct) }
  let(:target_project_id) { 'foo' }
  let(:process) { GoodData::MockFactory.process_mock(process_name, process_id) }
  let(:process_id) { 'my_test_process_id' }
  let(:process_name) { 'my_test_process_name' }
  let(:target_project) { double(GoodData::Project) }
  let(:target_process) { double(GoodData::Process) }
  let(:target_process_name) { process_name }
  let(:schedule_name) { 'my schedule' }
  let(:schedule) { GoodData::MockFactory.schedule_mock(schedule_name, process_id) }
  let(:target_schedule) { GoodData::MockFactory.schedule_mock(schedule_name, process_id) }
  let(:custom_target_process) { double(GoodData::Process) }
  let(:custom_target_process_name) { 'custom_client_process' }
  let(:custom_target_process_id) { 'custom_client_process_id' }
  let(:custom_target_schedule) { GoodData::MockFactory.schedule_mock('custom schedule', custom_target_process_id) }
  let(:params) do
    params = {
      gdc_logger: logger,
      gdc_gd_client: gdc_gd_client,
      organization: domain,
      synchronize: [{
        from: 'from project',
        segment_id: 'some_segment_ids',
        to: [{ pid: target_project_id, client_id: client_id }]
      }],
      data_product: data_product
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(gdc_gd_client).to receive(:projects).with('from project') { project }
    allow(gdc_gd_client).to receive(:projects).with(target_project_id) { project }
    allow(logger).to receive(:warn)
    allow(data_product).to receive(:segments) { [segment] }
    allow(segment).to receive(:synchronize_processes) { result }
    allow(project).to receive(:set_metadata)
    allow(segment).to receive(:segment_id) { 'some_segment_ids' }
    allow(project).to receive(:processes) { [process] }
    allow(gdc_gd_client).to receive(:projects)
      .with(target_project_id) { target_project }
    allow(target_project).to receive(:processes) { [target_process, custom_target_process] }
    allow(target_project).to receive(:set_metadata)
    allow(target_project).to receive(:schedules) { [custom_target_schedule, target_schedule] }
    allow(target_process).to receive(:name) { target_process_name }
    allow(custom_target_process).to receive(:name) { custom_target_process_name }
    allow(target_process).to receive(:process_id) { process_id }
    allow(custom_target_process).to receive(:process_id) { custom_target_process_id }
    allow(custom_target_process).to receive(:delete)
    allow(target_schedule).to receive(:enable)
    allow(target_schedule).to receive(:save)
    allow(project).to receive(:schedules) { [schedule] }
    allow(custom_target_schedule).to receive(:enable)
    allow(custom_target_schedule).to receive(:save)
    allow(custom_target_schedule).to receive(:delete)
  end

  it 'adds GOODOT_CUSTOM_PROJECT_ID to metadata' do
    expect(target_project).to receive(:set_metadata)
      .with('GOODOT_CUSTOM_PROJECT_ID', client_id)
    subject.class.call(params)
  end

  context 'when delete_extra_process_schedule is true' do
    let(:custom_params) { params.merge(delete_extra_process_schedule: false) }

    it 'keeps all processes in target project' do
      expect(target_process).not_to receive(:delete)
      expect(custom_target_process).not_to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end

    it 'keeps all schedules in target project' do
      expect(target_schedule).not_to receive(:delete)
      expect(custom_target_schedule).not_to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end

    it 'enables target schedules' do
      expect(target_schedule).to receive(:enable)
      expect(target_schedule).to receive(:save)
      expect(custom_target_schedule).to receive(:enable)
      expect(custom_target_schedule).to receive(:save)
      GoodData::LCM2.run_action(described_class, custom_params)
    end
  end

  context 'when delete_extra_process_schedule is true' do
    let(:custom_params) { params.merge(delete_extra_process_schedule: true) }

    before do
    end

    it 'keeps processes with the same name' do
      expect(target_process).not_to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end

    it 'deletes processes with a different name' do
      expect(custom_target_process).to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end

    it 'keeps schedules with the same process name' do
      expect(target_schedule).not_to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end

    it 'deletes schedules with a different process name' do
      expect(custom_target_schedule).to receive(:delete)
      GoodData::LCM2.run_action(described_class, custom_params)
    end
  end

  context 'when sync processes/schedules has problem' do
    let(:result) do
      {
        syncedResult: {
          errors: [
            {
              errorId: "91a811a7-8d3a-42d2-a1ba-024933f74021",
              errorCode: "gdc.lcm.schedule.fatal_error",
              message: "Error",
              parameters: []
            }
          ]
        }
      }
    end

    it 'raise error' do
      expect { subject.class.call(params) }.to raise_error
    end
  end

  context 'when sync processes/schedules has problem with warning status' do
    let(:result) do
      {
        syncedResult: {
          errors: [
            {
              errorId: "91a811a7-8d3a-42d2-a1ba-024933f74021",
              errorCode: "gdc.lcm.schedule.fatal_error",
              message: "Error",
              parameters: []
            }
          ]
        }
      }
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

    it 'process warning status' do
      # Action get errors but still continue process
      subject.class.call(warning_params)
      failed_detailed_projects = warning_params.sync_failed_list.failed_detailed_projects

      expect(failed_detailed_projects.size).to eq(1)
      expect(failed_detailed_projects[0][:segment]).to eq('some_segment_ids')
      expect(failed_detailed_projects[0][:message]).to include('Failed to sync processes/schedules for segment some_segment_ids')
      expect(failed_detailed_projects[0][:message]).to include('91a811a7-8d3a-42d2-a1ba-024933f74021')
      expect(failed_detailed_projects[0][:message]).to include('gdc.lcm.schedule.fatal_error')
    end
  end

  context 'when user passes dynamic schedule parameters' do
    let(:project) { double(:project) }
    let(:schedule1) { double(:schedule1) }
    let(:schedule2) { double(:schedule2) }

    before do
      allow(segment).to receive(:synchronize_processes).and_return(
        syncedResult: {
          clients: [
            client: {
              id: 'foo',
              project: 'bar'
            }
          ]
        }
      )
      allow(segment).to receive(:master_project_id)
      allow(schedule1).to receive(:update_hidden_params)
      allow(schedule1).to receive(:enable)
      allow(schedule1).to receive(:save)
      allow(schedule1).to receive(:name) { 'Schedule1' }
      allow(schedule2).to receive(:update_hidden_params)
      allow(schedule2).to receive(:enable)
      allow(schedule2).to receive(:save)
      allow(schedule2).to receive(:name) { 'Schedule2' }
      allow(project).to receive(:schedules) { [schedule1, schedule2] }
      allow(gdc_gd_client).to receive(:projects) { project }
    end

    context 'to each schedules' do
      let(:params) do
        params = {
          gdc_gd_client: gdc_gd_client,
          organization: domain,
          synchronize: [
            {
              segment_id: 'some_segment_ids',
              from: 'from project',
              to: [
                pid: '123',
                client_id: 'foo'
              ]
            }
          ],
          schedule_params: {
            all_clients: {
              'Schedule1' => {
                'HELLO': 'hi'
              },
              'Schedule2' => {
                'BYE': 'bye'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'each schedules must have different parameters' do
        expect(schedule1).to receive(:update_params).once.ordered.with('HELLO': 'hi')
        expect(schedule2).to receive(:update_params).once.ordered.with('BYE': 'bye')
        subject.class.call(params)
      end
    end

    context 'to all schedules' do
      let(:params) do
        params = {
          gdc_gd_client: gdc_gd_client,
          organization: domain,
          synchronize: [
            {
              segment_id: 'some_segment_ids',
              from: 'from project',
              to: [
                pid: '123',
                client_id: 'foo'
              ]
            }
          ],
          schedule_params: {
            all_clients: {
              all_schedules: {
                'HELLO': 'hi'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'all schedules must have the parameter' do
        expect(schedule1).to receive(:update_params).once.ordered.with('HELLO': 'hi')
        expect(schedule2).to receive(:update_params).once.ordered.with('HELLO': 'hi')
        subject.class.call(params)
      end
    end

    context 'to each schedules in each clients' do
      let(:params) do
        params = {
          gdc_gd_client: gdc_gd_client,
          organization: domain,
          synchronize: [
            {
              segment_id: 'some_segment_ids',
              from: 'from project',
              to: [
                pid: '123',
                client_id: 'foo'
              ]
            }
          ],
          schedule_params: {
            'foo' => {
              'Schedule1' => {
                'HELLO': 'hi'
              }
            },
            'bar' => {
              'Schedule2' => {
                'BYE': 'bye'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'parameters should be passed to the correct client project and schedule' do
        expect(schedule1).to receive(:update_params).once.ordered.with('HELLO': 'hi')
        subject.class.call(params)
      end
    end
  end
end
