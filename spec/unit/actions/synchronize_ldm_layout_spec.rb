# Copyright (c) 2022 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::SynchronizeLdmLayout do
  let(:development_client) { double(GoodData::Rest::Client) }
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:src_project) { double(GoodData::Project) }
  let(:dest_project) { double(GoodData::Project) }
  let(:gdc_logger) { double('logger') }
  let(:src_pid) { 'source_project_id' }
  let(:dest_pid) { 'dest_process_id' }
  let(:dest_client) { double(GoodData::Client) }
  let(:output) { { :from => "source_project_id", :to => "dest_process_id", :count => 0, :status => "OK" } }
  let(:synchronize) do
    GoodData::LCM2.convert_to_smart_hash([
                                           from: src_pid,
                                           to: [
                                             {
                                               pid: dest_pid,
                                               client_id: 'test_client_id'
                                             }
                                           ]
                                         ])
  end

  let(:params) do
    GoodData::LCM2.convert_to_smart_hash(
      synchronize: synchronize,
      development_client: development_client,
      gdc_gd_client: gdc_gd_client,
      gdc_logger: gdc_logger
    )
  end

  before do
    test_layout = {
      "ldmLayout" => {
        "layout" => [
          {
            "id" => "dataset_1",
            "type" => "dataset",
            "collapse" => true,
            "x" => 100.1,
            "y" => 200.2
          },
          {
            "id" => "date_1",
            "type" => "template_dataset",
            "collapse" => false,
            "x" => 150.1,
            "y" => 250.2
          }
        ]
      }
    }
    allow(GoodData::LdmLayout).to receive(:get).and_return(test_layout)
    allow_any_instance_of(GoodData::LdmLayout).to receive(:save).and_return(test_layout)
    allow(development_client).to receive(:projects).with(src_pid).and_return(src_project)
    allow(gdc_gd_client).to receive(:projects).with(dest_pid).and_return(dest_project)
    allow(src_project).to receive(:title).and_return('src title')
    allow(src_project).to receive(:ldm_layout).and_return(test_layout)
    allow(dest_project).to receive(:title).and_return('dest title')
    allow(dest_project).to receive(:save_ldm_layout).and_return(output)
    allow(src_project).to receive(:pid).and_return(src_pid)
    allow(dest_project).to receive(:pid).and_return(dest_pid)
    allow(dest_project).to receive(:client).and_return(dest_client)
    allow(src_project).to receive(:client).and_return(development_client)
    allow(gdc_logger).to receive(:info)
  end

  it 'synchronize ldm layout to target projects' do
    expected_res = [output]
    res = subject.class.call(params)
    expect(res).to eql(expected_res)
  end
end
