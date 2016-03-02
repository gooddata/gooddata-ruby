# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

RAW_DATA = {
  'metric'=>
  {'content'=>
    {'format'=>'#,##0',
     'expression'=> 'SELECT SUM([/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/700])'},
   'meta' =>
    {'author'=>'/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248',
     'uri'=>'/gdc/md/ksjy0nr3goz6k8yrpklz97l0mych7nez/obj/70',
     'tags'=>'a a   b cg r t',
     'created'=>'2014-04-30 22:47:57',
     'identifier'=>'afo7bx1VakCz',
     'deprecated'=>'0',
     'summary'=>'',
     'title'=>'sum of Lines changed',
     'category'=>'metric',
     'updated'=>'2014-05-05 20:00:42',
     'contributor'=>'/gdc/account/profile/4e1e8cacc4989228e0ae531b30853248'}}
}


describe GoodData::MdObject do
  before(:each) do
    @instance = GoodData::MdObject.new(GoodData::Helpers.deep_dup(RAW_DATA))
  end

  describe '#identifier=' do
    it 'Allows setting a new identifier' do
      identifier = @instance.identifier
      @instance.identifier = 'new_id'
      new_identifier = @instance.identifier

      expect(new_identifier).to_not eq identifier
      expect(new_identifier).to eq 'new_id'
    end
  end

  describe '#tag_list' do
    it 'returns tags as list' do
      expect(@instance.tag_set).to eq %w(a b cg r t).to_set
    end
  end

  describe '#add_tag' do
    it 'adds tag' do
      expect(@instance.add_tag('xx').tag_set).to eq %w(a b cg r t xx).to_set
    end
  end

  describe '#remove_tag' do
    it 'returns tags as list' do
      expect(@instance.remove_tag('t').tag_set).to eq %w(a b cg r).to_set
    end
  end

  describe '#deprecated' do
    it 'returns true/false' do
      expect(@instance.deprecated).to be_falsey
    end
  end

  describe '#deprecated=' do
    it 'sets deprecated flag' do
      expect(@instance.deprecated).to be_falsey
      @instance.deprecated = true
      expect(@instance.deprecated).to be_truthy
      @instance.deprecated = false
      expect(@instance.deprecated).to be_falsey
      @instance.deprecated = 0
      expect(@instance.deprecated).to be_falsey
      @instance.deprecated = 1
      expect(@instance.deprecated).to be_truthy
    end
  end

  describe '#unlisted' do
    it 'returns true/false' do
      expect(@instance.unlisted).to be_falsey
    end
  end

  describe '#unlisted?' do
    it 'returns true/false' do
      expect(@instance.unlisted?).to be_falsey
    end
  end

  describe '#unlisted=' do
    it 'sets unlisted flag' do
      expect(@instance.unlisted).to be_falsey
      @instance.unlisted = true
      expect(@instance.unlisted?).to be_truthy
      @instance.unlisted = false
      expect(@instance.unlisted?).to be_falsey
    end
  end
end
