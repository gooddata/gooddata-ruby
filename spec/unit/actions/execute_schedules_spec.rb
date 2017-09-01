# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/execute_schedules'

describe GoodData::LCM2::ExecuteSchedules do
  let(:client) { double(:client) }
  let(:logger) { double(:logger) }
  let(:project) { double(:project) }
  let(:schedule) { double(:schedule) }

  before do
    allow(logger).to receive(:info)
    allow(logger).to receive(:warn)
    allow(client).to receive(:projects).and_return([project])
    allow(schedule).to receive(:params).and_return('MODE' => 'foo')
    allow(schedule).to receive(:project).and_return(project)
    allow(schedule).to receive(:obj_id).and_return('id')
    allow(project).to receive(:schedules).and_return([schedule])
    allow(project).to receive(:pid)
    allow(project).to receive(:title)
  end

  context 'In simplest case' do
    let(:params) do
      params = {
        GDC_GD_CLIENT: client,
        list_of_modes: 'foo|bar',
        work_done_identificator: 'IGNORE',
        gdc_logger: logger
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'execute schedules' do
      expect(schedule).to receive(:execute)
      subject.class.call(params)
    end
  end

  context 'when SEGMENT_LIST is specified' do
    let(:params) do
      params = {
        GDC_GD_CLIENT: client,
        list_of_modes: 'foo|bar',
        work_done_identificator: 'IGNORE',
        gdc_logger: logger,
        segment_list: 'A|B'
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it 'throw error if DOMAIN is not filled' do
      expect do
        subject.class.call(params)
      end.to raise_error(/In case that you are using SEGMENT_LIST parameter, you need to fill out DOMAIN parameter/)
    end
  end

  context 'when SEGMENT_LIST and DOMAIN are specified' do
    let(:params) do
      params = {
        GDC_GD_CLIENT: client,
        list_of_modes: 'foo|bar',
        work_done_identificator: 'IGNORE',
        gdc_logger: logger,
        segment_list: 'A',
        domain: 'domain'
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    let(:domain) { double(:domain) }
    let(:segment) { double(:segment) }
    let(:segment_client) { double(:segment_client) }

    before do
      allow(client).to receive(:domain).and_return(domain)
      allow(domain).to receive(:segments).and_return(segment)
      allow(segment).to receive(:clients).and_return([segment_client])
      allow(project).to receive(:obj_id).and_return('id')
      allow(segment_client).to receive(:project).and_return(project)
    end

    it 'should work' do
      expect(schedule).to receive(:execute)
      subject.class.call(params)
    end
  end
end
