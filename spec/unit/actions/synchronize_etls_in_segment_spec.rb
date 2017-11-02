# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_etls_in_segment'

describe GoodData::LCM2::SynchronizeETLsInSegment do
  let(:gdc_gd_client) { double('gdc_gd_client') }
  let(:domain) { double('domain') }
  let(:segment) { double('segment') }
  let(:project) { double('project') }
  let(:result) { { syncedResult: {} } }
  let(:client_id) { 'foo_client' }
  let(:data_product) { double('data_product') }
  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      organization: domain,
      synchronize: [{
        segment_id: 'some_segment_ids',
        to: [{ pid: 'foo', client_id: client_id }]
      }],
      data_product: data_product
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(gdc_gd_client).to receive(:domain) { domain }
    allow(gdc_gd_client).to receive(:projects) { project }
    allow(project).to receive(:schedules) { [] }
    allow(data_product).to receive(:segments) { [segment] }
    allow(segment).to receive(:synchronize_processes) { result }
    allow(project).to receive(:set_metadata)
    allow(segment).to receive(:segment_id) { 'some_segment_ids' }
  end

  it 'adds GOODOT_CUSTOM_PROJECT_ID to metadata' do
    expect(project).to receive(:set_metadata)
      .with('GOODOT_CUSTOM_PROJECT_ID', client_id)
    subject.class.call(params)
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
                'HELLO' => 'hi'
              },
              'Schedule2' => {
                'BYE' => 'bye'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'each schedules must have different parameters' do
        schedule1.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        schedule1.should_receive(:update_params).once.ordered.with('HELLO' => 'hi')
        schedule2.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        schedule2.should_receive(:update_params).once.ordered.with('BYE' => 'bye')
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
                'HELLO' => 'hi'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'all schedules must have the parameter' do
        schedule1.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        schedule1.should_receive(:update_params).once.ordered.with('HELLO' => 'hi')
        schedule2.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        schedule2.should_receive(:update_params).once.ordered.with('HELLO' => 'hi')
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
                'HELLO' => 'hi'
              }
            },
            'bar' => {
              'Schedule2' => {
                'BYE' => 'bye'
              }
            }
          },
          data_product: data_product
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      it 'parameters should be passed to the correct client project and schedule' do
        schedule1.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        schedule1.should_receive(:update_params).once.ordered.with('HELLO' => 'hi')
        schedule2.should_receive(:update_params).once.ordered.with(CLIENT_ID: 'foo', GOODOT_CUSTOM_PROJECT_ID: 'foo')
        subject.class.call(params)
      end
    end
  end
end
