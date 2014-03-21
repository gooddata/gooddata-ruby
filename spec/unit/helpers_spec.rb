# encoding: UTF-8

require 'gooddata/client'
require 'gooddata/models/model'

describe GoodData::Helpers do
  describe '#home_directory' do
    it 'works' do
      GoodData::Helpers.home_directory
    end
  end

  describe '#running_on_windows?' do
    it 'works' do
      result = GoodData::Helpers.running_on_windows?
      !!result.should == result
    end
  end

  describe '#running_on_mac?' do
    it 'works' do
      result = GoodData::Helpers.running_on_a_mac?
      !!result.should == result
    end
  end

  describe '#error' do
    it 'works' do
      expect { GoodData::Helpers.error('Test Error') }.to raise_error(SystemExit)
    end
  end

  describe '#find_goodfile' do
    it 'works' do
      pending "Ask @fluke777 how to create one"
      GoodData::Helpers.find_goodfile.should_not be_nil
    end
  end

  describe '#sanitize_string' do
    it 'works' do
      expect = 'helloworld'
      result = GoodData::Helpers.sanitize_string('Hello World')
      result.should == expect
    end
  end
end
