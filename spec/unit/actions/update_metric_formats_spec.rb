# Copyright (c) 2010-2021 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::UpdateMetricFormats do
  let(:development_client) { double(GoodData::Rest::Client) }
  let(:gdc_gd_client) { double(GoodData::Rest::Client) }
  let(:client_project) { double(GoodData::Project) }
  let(:metric) { double(GoodData::Metric) }
  let(:data_product) {double GoodData::DataProduct}
  let(:src_pid) { 'source_project_id' }
  let(:dest_pid) { 'dest_process_id' }
  let(:datasource) { double(:datasource) }
  let(:output) { [{:client_id=>"client_01", :tag=>"metric_currency", :format=>"E##.000"},
                  {:client_id=>"client_01", :tag=>"metric_number", :format=>"#0.000"},
                  {:client_id=>"client_02", :tag=>"metric_currency", :format=>"US##.000"},
                  {:client_id=>"client_02", :tag=>"metric_number", :format=>"##0.000"}] }
  let(:synchronize) do
    GoodData::LCM2.convert_to_smart_hash([
                                           from: src_pid,
                                           to: [
                                             {
                                               pid: dest_pid,
                                               client_id: 'client_01'
                                             }
                                           ]
                                         ])
  end

  let(:input_source) do
    GoodData::LCM2.convert_to_smart_hash({
                                                 "type": "ads",
                                                 "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;",
                                                 "metric_format": {
                                                     "query": "SELECT client_id, tag, format FROM metric_formats;"
                                                 }
                                             }
                                         )
  end

  let(:params) do
    GoodData::LCM2.convert_to_smart_hash(
      synchronize: synchronize,
      development_client: development_client,
      gdc_gd_client: gdc_gd_client,
      data_product: data_product,
      input_source: input_source
    )
  end

  before do
    allow(GoodData::Helpers::DataSource).to receive(:new).and_return(datasource)
    allow(datasource).to receive(:realize).and_return('spec/data/metric_formats_table.csv')
    allow(data_product).to receive(:clients).and_return([gdc_gd_client])
    allow(gdc_gd_client).to receive(:id).and_return("client_01")
    allow(gdc_gd_client).to receive(:project).and_return(client_project)
    allow(client_project).to receive(:metrics).and_return([metric])
    allow(metric).to receive(:save).and_return({})
    allow(metric).to receive(:tags).and_return(["metric_currency"])
    allow(metric).to receive(:to_a).and_return("")
    allow(metric).to receive(:format=).and_return("")
    allow(metric).to receive(:title).and_return("title")
  end

  context 'when load metric data' do
    it 'successfully' do
      expected = output
      res = subject.class.load_metric_data(params)
      expect(res).to eql(expected)
    end

    it 'with no metric config' do
      expected = nil
      params = {
          input_source: {
              "type": "ads",
              "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;"
          }
      }
      res = subject.class.load_metric_data(GoodData::LCM2.convert_to_smart_hash(params))
      expect(res).to eql(expected)
    end

    it 'with empty metric config' do
      expected = nil
      params = {
          input_source: {
              "type": "ads",
              "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;",
              "metric_format": {}
          }
      }
      res = subject.class.load_metric_data(GoodData::LCM2.convert_to_smart_hash(params))
      expect(res).to eql(expected)
    end

    it 'with blank metric' do
      expected = nil
      params = {
          input_source: {
              "type": "ads",
              "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;",
              "metric_format": ""
          }
      }
      res = subject.class.load_metric_data(GoodData::LCM2.convert_to_smart_hash(params))
      expect(res).to eql(expected)
    end

    it 'with no type config' do
      params = {
          input_source: {
              "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;",
              "metric_format": {
                  "query": "Select"
              }
          }
      }
      expect do
        subject.class.load_metric_data(GoodData::LCM2.convert_to_smart_hash(params))
      end.to raise_exception "Incorrect configuration: 'type' of 'input_source' is required"
    end

    it 'with type is blank' do
      params = {
          input_source: {
              "type": "",
              "query": "SELECT DISTINCT client_id, segment_id, project_title, project_token FROM lcm_workspace;",
              "metric_format": {
                  "query": "Select"
              }
          }
      }
      expect do
        subject.class.load_metric_data(GoodData::LCM2.convert_to_smart_hash(params))
      end.to raise_exception "Incorrect configuration: 'type' of 'input_source' is required"
    end
  end

  context 'when get client metric' do
    it 'successfully' do
      expected = output
      res = subject.class.load_metric_data(params)
      expect(res).to eql(expected)

      expected = {"client_01" => {"metric_currency"=>"E##.000", "metric_number"=>"#0.000"},
                  "client_02" => {"metric_currency"=>"US##.000", "metric_number"=>"##0.000"}}
      res = subject.class.get_clients_metrics(res)
      expect(res).to eql(expected)
    end
  end

  context 'when modify input_source' do
    it 'type ads' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                               "type": "ads",
                                               "query": "Dummy",
                                               "metric_format": {
                                                   "query": "SELECT client_id, tag, format FROM metric_formats;"
                                               }
                                           }
      )
      expected = {:type=>"ads", :query=>"SELECT client_id, tag, format FROM metric_formats;",
                  :metric_format=>{:query=>"SELECT client_id, tag, format FROM metric_formats;"}}
      res = subject.class.validate_input_source(input_source, false)
      expect(res).to eql(expected)
    end

    it 'type dwh' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                                              "type": "snowflake",
                                                              "query": "Dummy",
                                                              "metric_format": {
                                                                  "query": "SELECT client_id, tag, format FROM metric_formats;"
                                                              }
                                                          }
      )
      expected = {:type=>"snowflake", :query=>"SELECT client_id, tag, format FROM metric_formats;",
                  :metric_format=>{:query=>"SELECT client_id, tag, format FROM metric_formats;"}}
      res = subject.class.validate_input_source(input_source, false)
      expect(res).to eql(expected)
    end

    it 'type s3 and aws_client' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                                              "type": "s3",
                                                              "key": "Dummy",
                                                              "metric_format": {
                                                                  "file": "The path to csv file"
                                                              }
                                                          }
      )
      expected = {:type=>"s3", :key=>"The path to csv file",
                  :metric_format=>{:file=>"The path to csv file"}}
      res = subject.class.validate_input_source(input_source, false)
      expect(res).to eql(expected)
    end

    it 'type s3 and s3_client' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                                              "type": "s3",
                                                              "file": "Dummy",
                                                              "metric_format": {
                                                                  "file": "The path to csv file"
                                                              }
                                                          }
      )
      expected = {:type=>"s3", :file=>"The path to csv file",
                  :metric_format=>{:file=>"The path to csv file"}}
      res = subject.class.validate_input_source(input_source, false)
      expect(res).to eql(expected)
    end

    it 'type web' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                                              "type": "web",
                                                              "url": "Dummy",
                                                              "metric_format": {
                                                                  "url": "The test url"
                                                              }
                                                          }
      )
      expected = {:type=>"web", :url=>"The test url",
                  :metric_format=>{:url=>"The test url"}}
      res = subject.class.validate_input_source(input_source, false )
      expect(res).to eql(expected)
    end

    it 'with incorrect values' do
      input_source = GoodData::LCM2.convert_to_smart_hash({
                                                              "type": "ads",
                                                              "url": "Dummy",
                                                              "metric_format": {
                                                                  "url": "The test url"
                                                              }
                                                          }
      )
      expected = nil
      res = subject.class.validate_input_source(input_source, false)
      expect(res).to eql(expected)
    end
  end

  context 'when update metrics format' do
    it 'for matched clients' do
      expected = [{:action=>"Update metric format", :ok_clients=>1, :error_clients=>0}]
      res = subject.class.call(params)
      expect(res).to eql(expected)
    end

    it 'for not matched clients' do
      params[:synchronize][0][:to] = [
          {
              pid: dest_pid,
              client_id: 'client_01_xx'
          }
      ]
      expected = [{:action=>"Update metric format", :ok_clients=>0, :error_clients=>0}]
      res = subject.class.call(params)
      expect(res).to eql(expected)
    end
  end

end
