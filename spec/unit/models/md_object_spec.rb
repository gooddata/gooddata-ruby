# encoding: UTF-8

require 'gooddata/models/md_object'

describe GoodData::Model::MdObject do
  TEST_TITLE = 'Test Title'
  TEST_NAME = 'Test Name'

  before(:each) do
    @instance = GoodData::Model::MdObject.new()
    @instance.title = TEST_TITLE
    @instance.name = TEST_NAME
  end

  describe '#initialize' do
    it 'Creates new instance' do
      @instance.should_not == nil
      @instance.should be_an_instance_of(GoodData::Model::MdObject)
    end
  end

  describe '#visual' do
    it 'Returns visual representation' do
      result = @instance.visual
      result.should_not == nil
      result.should be_an_instance_of(String)
    end
  end

  describe '#title_esc' do
    it 'Returns escaped title' do
      result = @instance.title_esc
      result.should_not == nil
      result.should be_an_instance_of(String)
    end
  end

  describe '#identifier' do
    it 'Returns identifier' do
      pending('GoodData::Model::MdObject::type_prefix is not defined')

      result = @instance.identifier
      result.should_not == nil
      result.should == be_an_instance_of(String)
    end
  end

  describe '#all' do
    it 'Throws an error. This is implemented on subclasses' do
      expect do
        GoodData::MdObject.all
      end.to raise_exception(NotImplementedError)
    end
  end
end
