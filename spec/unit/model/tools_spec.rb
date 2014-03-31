# encoding: UTF-8

require 'gooddata/client'
require 'gooddata/models/model'

describe GoodData::Model do
  COLUMNS = [
    {:type =>:anchor, :name =>'cp', 'title' => 'CP', 'folder' => 'test'},
    {:type =>:attribute, :name =>'a1', 'title' => 'A1', 'folder' => 'test'},
    {:type =>:attribute, :name =>'a2', 'title' => 'A2', 'folder' => 'test'},
    {:type =>:date, :name =>'event', 'title' => 'Event', 'folder' => 'test'},
    {:type =>:fact, :name =>'f1', 'title' => 'F1', 'folder' => 'test'},
    {:type =>:fact, :name =>'f2', 'title' => 'F2', 'folder' => 'test'},
  ]
  SCHEMA = GoodData::Model::Schema.new :name => 'test', :title => 'test', :columns => COLUMNS

  before(:all) do
    GoodData::connect
  end

  it 'generate identifiers starting with letters and without ugly characters' do
    pending('Research what is desired behavior')

    expect = 'fact.test.blah'
    result = GoodData::Model::Fact.new({:name =>'blah'}, SCHEMA).identifier
    result.should == expect

    expect = 'attr.test.blah'
    result = GoodData::Model::Attribute.new({:name =>'1_2_3 blah'}, SCHEMA).identifier
    result.should == expect

    expect = 'dim.blaz'
    result = GoodData::Model::AttributeFolder.new(' b*ĺ*á#ž$').identifier
    result.should == expect
  end

  it "create a simple model in a sandbox project using project.model.add_dataset" do
    pending "Throws 400 - Bad request now"

    project = GoodData::Project.create :title => "gooddata-ruby test #{Time.new.to_i}"
    objects = project.add_dataset 'Mrkev', COLUMNS

    uris = objects['uris']
    uris[0].should == "#{project.md['obj']}/1"
    # fetch last object (temporary objects can be placed at the begining of the list)
    GoodData.get uris[uris.length - 1]
    project.delete
  end

  it "create a simple model in a sandbox project using Model.add_dataset" do
    pending "Throws 400 - Bad request now"

    project = GoodData::Project.create :title => "gooddata-ruby test #{Time.new.to_i}"
    GoodData.use project
    objects = GoodData::Model.add_dataset 'Mrkev', COLUMNS

    uris = objects['uris']
    uris[0].should == "#{project.md['obj']}/1"

    # fetch last object (temporary objects can be placed at the begining of the list)
    GoodData.get uris[uris.length - 1]

    # created model should define SLI interface on the 'Mrkev' data set
    # TODO move this into a standalone test covering gooddata/metadata.rb
    ds = GoodData::DataSet['dataset.mrkev']
    ds.should_not be_nil

    project.delete
  end

  it "create a simple model with no CP in a sandbox project using Model.add_dataset" do
    pending "Throws 400 - Bad request now"

    project = GoodData::Project.create :title => "gooddata-ruby test #{Time.new.to_i}"
    GoodData.use project

    # create a similar data set but without the connection point column
    cols_no_cp = COLUMNS.select { |c| c['type'] != 'CONNECTION_POINT' }
    objects = GoodData::Model.add_dataset 'No CP', cols_no_cp
    uris = objects['uris']

    # Repeat check of metadata objects expected to be created on the server side
    GoodData.get uris[uris.length - 1]
    ds = GoodData::DataSet['dataset.nocp']
    ds.should_not be_nil

    # clean-up
    project.delete
  end
end
