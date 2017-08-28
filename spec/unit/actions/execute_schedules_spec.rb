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

  let(:params) do
    params = {
      GDC_GD_CLIENT: client,
      list_of_modes: 'foo|bar',
      work_done_identificator: 'IGNORE',
      gdc_logger: logger
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

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

  it 'execute schedules' do
    expect(schedule).to receive(:execute)
    subject.class.call(params)
  end
end
