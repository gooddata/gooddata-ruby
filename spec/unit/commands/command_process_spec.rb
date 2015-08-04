# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/commands/process'

describe GoodData::Command::Process do
  deploy_dir = File.join(File.dirname(__FILE__), '..', '..', 'data/cc')
  graph_path = 'graph/graph.grf'

  before(:each) do
    @client = ConnectionHelper.create_default_connection
    @project = ProjectHelper.get_default_project(:client => @client)
  end

  after(:each) do
    @client.disconnect
  end

  it "Is Possible to create GoodData::Command::Process instance" do
    cmd = GoodData::Command::Process.new()
    cmd.should be_a(GoodData::Command::Process)
  end

  describe "#get" do
    it "Should throw exception if no Project ID specified" do
      expect { GoodData::Command::Process.get }.to raise_error
    end

    it "Should throw exception if no Process ID specified" do
      expect { GoodData::Command::Process.get(project_id: ProjectHelper::PROJECT_ID, client: @client) }.to raise_error
    end

    it "Gets process by process ID" do
      res = GoodData::Command::Process.get(project_id: ProjectHelper::PROJECT_ID, process_id: ProcessHelper::PROCESS_ID, client: @client)
      expect(res).to_not be_nil
      expect(res).to be_an_instance_of(GoodData::Process)
    end
  end

  describe "#deploy" do
    it "Throws exception if no project specified" do
      GoodData::Command::Process.deploy(deploy_dir, name: ProcessHelper::DEPLOY_NAME, project_id: ProjectHelper::PROJECT_ID, client: @client, project: @project)
    end

    it "Deploys graph" do
      GoodData::Command::Process.deploy(deploy_dir, name: ProcessHelper::DEPLOY_NAME, project_id: ProjectHelper::PROJECT_ID, client: @client, project: @project)
    end
  end

  describe "#execute_process" do
    it "Throws exceptions when wrong URL specified" do
      link = "/gdc"
      expect do
        GoodData::Command::Process.execute_process(link, deploy_dir)
      end.to raise_exception
    end
  end

  describe "#list" do
    it "Returns processes" do
      res = GoodData::Command::Process.list(project_id: ProjectHelper::PROJECT_ID, client: @client, project: @project)
      expect(res).to be_an_instance_of(Array)
    end
  end

  describe "#run" do
    it "Throws exception if no project specified" do
      expect { GoodData::Command::Process.run(deploy_dir, graph_path) }.to raise_error
    end

    it "Runs process" do
      # GoodData::Command::Process.run(deploy_dir, graph_path)
    end
  end

  describe "#with_deploy" do
    it "Should throw exception if no project specified" do
      expect do
        GoodData::Process.with_deploy('./spec/data/hello_world_process', type: :ruby, name: ProcessHelper::DEPLOY_NAME, client: @client) do
          msg = "Hello World!"
        end
      end.to raise_error
    end

    it "Executes block when deploying" do
      msg = nil
      GoodData::Process.with_deploy('./spec/data/hello_world_process', type: :ruby, name: ProcessHelper::DEPLOY_NAME, client: @client, project: @project) do
        msg = 'Hello World!'
      end
      expect(msg).to eq 'Hello World!'
    end
  end

end