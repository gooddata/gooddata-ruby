# encoding: UTF-8

require 'gooddata'

describe GoodData::Shell do
  describe '#initialize' do
    it 'Creates new instance' do
      inst = GoodData::Shell.new()
      inst.should_not == nil
    end
  end

  describe '#prompt' do
    before(:all) do
      @shell = GoodData::Shell.new
    end

    it 'Returns prompt' do
      expected = '> '
      res = @shell.prompt

      res.should == expected
    end
  end

  describe '#process_line' do
    before(:all) do
      @shell = GoodData::Shell.new
    end

    it "Processes 'help' line"  do
      expected = 0
      res = @shell.process_line('help')
      res.should == expected
    end
  end
end