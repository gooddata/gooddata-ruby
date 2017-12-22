# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::Report, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @project, @blueprint = ProjectHelper.load_full_project_implementation(@client)

    m = @project.facts.first.create_metric
    metric_name = Dir::Tmpname.make_tmpname ['metric.some_metric'], nil
    metric_name.delete!('-')
    m.identifier = metric_name
    m.save

    test_data = [
      %w(lines_changed committed_on dev_id repo_id),
      [3, "05/01/2012", 1_012, 75],
      [2, "11/10/2014", 5_432, 23],
      [5, "01/10/2014", 45_212, 87_163],
      [1, "12/02/2017", 753, 11]
    ]
    @project.upload(test_data, @blueprint, 'dataset.commits')

    m = @project.metrics.first
    @report = @project.create_report(top: [m], title: 'Report to export')
    @report.save
  end

  after(:all) do
    @project.delete unless @project.nil?
    @client.disconnect
  end

  describe 'raw export' do
    before :each do
      @filename = Dir::Tmpname.make_tmpname([File.join(Dir.pwd, Dir::Tmpname.tmpdir, 'test_raw_export'), '.csv'], nil)
    end

    after :each do
      File.delete(@filename)
    end

    it "exports raw report" do
      @report.export_raw(@filename)
      expect(File).to exist(@filename)
      expect(File.read(@filename)).to eq("\"sum of Lines Changed\"\r\n\"11.00\"\r\n")
    end
  end
end
