# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'
require 'gooddata/lcm/actions/synchronize_user_groups'

describe GoodData::LCM2::SynchronizeUserGroups do
  let(:gdc_gd_client) { double(:gdc_gd_client) }
  let(:development_client) { double(:development_client) }
  let(:logger) { double(:logger) }

  let(:from_project) { double(:from_project) }
  let(:to_project) { double(:to_project) }

  let(:params) do
    params = {
      gdc_gd_client: gdc_gd_client,
      development_client: development_client,
      synchronize: [{
        segment_id: 'some_segment_ids',
        from: 'from_project_id',
        to: [{ pid: 'to_project_id' }]
      }],
      gdc_logger: logger
    }
    GoodData::LCM2.convert_to_smart_hash(params)
  end

  before do
    allow(logger).to receive(:info)

    allow(development_client).to receive(:projects) { from_project }
    allow(from_project).to receive(:title)
    allow(from_project).to receive(:pid)

    allow(gdc_gd_client).to receive(:projects) { to_project }
    allow(to_project).to receive(:title)
    allow(to_project).to receive(:pid)
  end

  it 'should transfer user groups' do
    result = [{ from: 'from_project_id', to: 'to_project_id', user_group: 'user_group_name', status: 'created' }]
    expect(GoodData::Project).to receive(:transfer_user_groups).with(from_project, to_project).and_return(result)
    subject.class.call(params)
  end
end
