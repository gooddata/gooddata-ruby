# encoding: UTF-8

require 'gooddata/models/metadata/metric'

describe GoodData::Metric do


  RAW_DATA2 = {'metric' =>
                 {'content' =>
                    {'format' => '#,##0',
                     'expression' => 'SELECT SUM([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/700])'},
                  'meta' =>
                    {'author' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248',
                     'uri' => '/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/70',
                     'tags' => 'a b cg r t',
                     'created' => '2014-04-30 22:47:57',
                     'identifier' => 'afo7bx1VakCz',
                     'deprecated' => '0',
                     'summary' => '',
                     'title' => 'sum of Lines changed',
                     'category' => 'metric',
                     'updated' => '2014-05-05 20:00:42',
                     'contributor' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248'}}}

  RAW_DATA3 = {'metric' =>
                 {'content' =>
                    {'format' => '#,##0',
                     'expression' => 'SELECT SUM([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/710])'},
                  'meta' =>
                    {'author' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248',
                     'uri' => '/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/71',
                     'tags' => 'a b cg r t',
                     'created' => '2014-04-30 22:47:57',
                     'identifier' => 'afo7bx1VakCz',
                     'deprecated' => '0',
                     'summary' => '',
                     'title' => 'sum of Lines changed',
                     'category' => 'metric',
                     'updated' => '2014-05-05 20:00:42',
                     'contributor' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248'}}}

  USED_METRIC = GoodData::Metric.new(RAW_DATA2)
  UNUSED_METRIC = GoodData::Metric.new(RAW_DATA3)

  RAW_DATA = {'metric' =>
                {'content' =>
                   {'format' => '#,##0',
                    'expression' =>
                      "SELECT SUM([#{USED_METRIC.uri})"},
                 'meta' =>
                   {'author' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248',
                    'uri' => '/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/252',
                    'tags' => 'a b cg r t',
                    'created' => '2014-04-30 22:47:57',
                    'identifier' => 'afo7bx1VakCz',
                    'deprecated' => '0',
                    'summary' => '',
                    'title' => 'sum of Lines changed',
                    'category' => 'metric',
                    'updated' => '2014-05-05 20:00:42',
                    'contributor' => '/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248'}}}

  before(:each) do
    @instance = GoodData::Metric.new(RAW_DATA)
  end

  describe '#contain?' do
    it 'should say it contains a depending metric if it does' do
      @instance.contain?(USED_METRIC).should == true
    end

    it 'should say it contains a depending object which is given as a string if it does' do
      @instance.contain?(USED_METRIC).should == true
    end

    it 'should be able to replace an object if the object is used in the expression' do
      pending('resolve mutating constant if I init from it')
    end

    it 'should be able to return an expression of the metric' do
      @instance.expression.should == "SELECT SUM([#{USED_METRIC.uri})"
    end

    it 'should be able to replace an object if the object is used in the expression' do
      @instance.contain?(USED_METRIC).should == true
      @instance.contain?(UNUSED_METRIC).should == false
      @instance.replace(USED_METRIC, UNUSED_METRIC)
      @instance.contain?(USED_METRIC).should == false
      @instance.contain?(UNUSED_METRIC).should == true
    end
  end
end
