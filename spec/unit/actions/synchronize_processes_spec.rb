# Copyright (c) 2010-2018 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::SynchronizeProcesses do
  let(:development_client) { double(GoodData::Rest::Client) }
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:src_project) { double(GoodData::Project) }
  let(:dest_project) { double(GoodData::Project) }
  let(:gdc_logger) { double('logger') }
  let(:src_pid) { '123' }
  let(:dest_pid) { '234' }
  let(:process) { double(GoodData::Process) }
  let(:dest_client) { double(GoodData::Client) }
  let(:add) { double(GoodData::AutomatedDataDistribution) }
  let(:output_stage) { double(GoodData::AdsOutputStage) }
  let(:synchronize) do
    GoodData::LCM2.convert_to_smart_hash([
                                           from: src_pid,
                                           to: [
                                             {
                                               pid: dest_pid,
                                               client_id: 'aaaa'
                                             }
                                           ]
                                         ])
  end
  let(:process_component) do
    { name: 'etl-csv-uploader' }
  end
  let(:process_hash) do
    { process: { component: process_component } }
  end
  let(:process_additional_hidden_params) do
    {
      process: {
        component: {
          secretConfig: {
            key: 'val'
          }
        }
      }
    }
  end
  let(:params) do
    GoodData::LCM2.convert_to_smart_hash(
      synchronize: synchronize,
      development_client: development_client,
      gdc_gd_client: gdc_gd_client,
      gdc_logger: gdc_logger,
      process_additional_hidden_params: process_additional_hidden_params
    )
  end

  before do
    allow(development_client).to receive(:projects).with(src_pid).and_return(src_project)
    allow(gdc_gd_client).to receive(:projects).with(dest_pid).and_return(dest_project)

    allow(src_project).to receive(:title).and_return('src title')
    allow(dest_project).to receive(:title).and_return('dest title')
    allow(src_project).to receive(:pid).and_return(src_pid)
    allow(dest_project).to receive(:pid).and_return(dest_pid)
    allow(src_project).to receive(:processes).and_return([process])
    allow(dest_project).to receive(:processes).and_return([])
    allow(dest_project).to receive(:client).and_return(dest_client)
    allow(src_project).to receive(:add).and_return(add)
    allow(dest_project).to receive(:add).and_return(add)
    allow(src_project).to receive(:client).and_return(development_client)

    allow(add).to receive(:output_stage).and_return(output_stage)
    allow(output_stage).to receive(:output_stage_prefix).and_return('prefix')
    allow(output_stage).to receive(:schema).and_return({})
    allow(output_stage).to receive(:client_id=)

    allow(gdc_logger).to receive(:info)

    allow(process).to receive(:name).and_return('process name')
    allow(process).to receive(:type).and_return('etl')
    allow(process).to receive(:path).and_return(nil)
    allow(process).to receive(:component).and_return(process_component)
    allow(process).to receive(:to_hash).and_return(process_hash)
    allow(process).to receive(:data).and_return(process_hash)
    allow(process).to receive(:data_sources).and_return([])

    allow(process).to receive(:project).and_return(src_project)
    allow(process).to receive(:add_v2_component?).and_return(false)
  end
  it 'merges the process params with the component part' do
    expect(GoodData::Process).to receive(:deploy_component).with(
      {
        process: {
          component: {
            name: 'etl-csv-uploader',
            secretConfig: {
              key: 'val'
            }
          },
          dataSources: []
        }
      },
      client: dest_client,
      project: dest_project
    )
    subject.class.call(params)
  end
end
