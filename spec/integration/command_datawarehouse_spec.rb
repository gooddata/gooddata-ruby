require 'gooddata/commands/datawarehouse'

describe GoodData::Command::DataWarehouse do
  before(:each) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:each) do
    @client.disconnect
  end

  it "Is Possible to create GoodData::Command::DataWarehouse instance" do
    cmd = GoodData::Command::DataWarehouse.new()
    cmd.should be_a(GoodData::Command::DataWarehouse)
  end

  it "Can create a data warehouse" do
    title = 'my warehouse'
    summary = 'hahahaha'
    dwh = nil

    begin
      dwh = GoodData::Command::DataWarehouse.create(title: title, summary: summary, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT, client: @client)

      expect(dwh.title).to eq(title)
      expect(dwh.summary).to eq(summary)
      expect(dwh.id).not_to be_nil
      expect(dwh.status).to eq('ENABLED')
    ensure
      dwh.delete if dwh
    end
  end
end