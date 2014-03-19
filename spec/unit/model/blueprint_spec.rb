require 'pry'
require 'gooddata/models/model'

describe GoodData::Model::ProjectBlueprint do

  before(:each) do
    @valid_blueprint = GoodData::Model::ProjectBlueprint.new(
        {
            title: 'x',
            datasets: [
                {
                    name: 'payments',
                    columns: [
                        {
                            type: 'attribute',
                            name: 'id'
                        },
                        {
                            type: 'fact',
                            name: 'amount'
                        },
                        {
                            type: 'reference',
                            name: 'user_id',
                            dataset: 'users',
                            reference: 'user_id'
                        },
                    ]
                },
                {
                    name: 'users',
                    columns: [
                        {
                            type: 'anchor',
                            name: 'user_id'
                        },
                        {
                            type: 'fact',
                            name: 'amount'
                        }
                    ]
                }
            ]})

    @invalid_blueprint = GoodData::Model::ProjectBlueprint.new(
        {
            title: 'x',
            datasets: [
                {
                    name: 'payments',
                    columns: [
                        {
                            type: 'attribute',
                            name: 'id'
                        },
                        {
                            type: 'fact',
                            name: 'amount'
                        },
                        {
                            type: 'reference',
                            name: 'user_id',
                            dataset: 'users',
                            reference: 'user_id'
                        },
                    ]
                },
                {
                    name: 'users',
                    columns: [
                        {
                            type: 'attribute',
                            name: 'user_id'
                        },
                        {
                            type: 'fact',
                            name: 'amount'
                        }
                    ]
                }
            ]})

    # @valid_blueprint = blueprint = BlueprintHelper.blueprint_from_file(File.join(File.dirname(__FILE__), '../data', 'blueprint_valid.json'))

    # @invalid_blueprint = BlueprintHelper.blueprint_from_file(File.join(File.dirname(__FILE__), '../data', 'blueprint_valid.json'))
  end

  it "valid blueprint should be marked as valid" do
    @valid_blueprint.model_valid?.should == true
  end

  it "valid blueprint should give you empty array of errors" do
    expect(@valid_blueprint.model_validate).to be_empty
  end

  it "invalid blueprint should be marked as invalid" do
    @invalid_blueprint.model_valid?.should == false
  end

  it "invalid blueprint should give you list of violating references" do
    errors = @invalid_blueprint.model_validate
    errors.size.should == 1
    errors.first.should == {
        type: 'reference',
        name: 'user_id',
        dataset: 'users',
        reference: 'user_id'
    }
  end

  it "references return empty array if there is no reference" do
    refs = @valid_blueprint.get_dataset("users").references
    expect(refs).to be_empty
  end

  it "should be able to get dataset by name" do
    ds = @valid_blueprint.get_dataset("users")
    ds.name.should == "users"
  end

  it "should tell you it has anchor when it does" do
    ds = @valid_blueprint.get_dataset("users")
    ds.has_anchor?.should == true
  end

  it "should tell you it does not have anchor when it does not" do
    ds = @invalid_blueprint.get_dataset("users")
    ds.has_anchor?.should == false
  end


end