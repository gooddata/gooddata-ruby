require 'gooddata/commands/process'

describe GoodData::Command::Process do
  deploy_dir = './'

  before(:each) do
    ConnectionHelper.create_default_connection
  end

  after(:each) do
    GoodData.disconnect
  end

  it "Is Possible to create GoodData::Command::Process instance" do
    cmd = GoodData::Command::Process.new()
    cmd.should be_a(GoodData::Command::Process)
  end

  describe "#get" do
    it "Should throw exception if no project specified" do
      expect { GoodData::Command::Process.get }.to raise_error
    end

    it "Returns processes" do
      pending('Project ID needed')
      GoodData::Command::Process.get
    end
  end

  describe "#deploy" do
    it "Throws exception if no project specified" do
      expect { GoodData::Command::Process.deploy(deploy_dir) }.to_not raise_error
    end

    it "Deploys graph" do
      pending('Project ID needed')
      GoodData::Command::Process.deploy(deploy_dir)
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
    it "Should throw exception if no project specified" do
      expect { GoodData::Command::Process.list }.to raise_error
    end

    it "Returns processes" do
      pending('Project ID needed')
      GoodData::Command::Process.list
    end
  end

  describe "#run" do
    it "Throws exception if no project specified" do
      pending("Run was removed for now.")
      expect { GoodData::Command::Process.run(deploy_dir) }.to raise_error
    end

    it "Runs process" do
      pending('Project ID needed')
      GoodData::Command::Process.run(deploy_dir)
    end
  end

  describe "#with_deploy" do
    it "Should throw exception if no project specified" do
      expect do
        GoodData::Command::Process.with_deploy(deploy_dir) do
          msg = "Hello World!"
        end

      end.to raise_error
    end

    it "Executes block when deploying" do
      pending('Project ID needed')
      GoodData::Command::Process.with_deploy(deploy_dir) do
        msg = "Hello World!"
      end
    end
  end

end