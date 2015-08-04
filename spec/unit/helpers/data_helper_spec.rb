# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/data_helper'

describe GoodData::Helpers::DataSource do
  before :each do
    @s3_client = double('s3_client')
    @buckets = double('buckets')
    @bucket = double('bucket')
    @objects = double('objects')

    allow(@s3_client).to receive(:buckets) { @buckets }
    allow(@buckets).to receive(:[]) { @bucket }
    allow(@bucket).to receive(:objects) { @objects }
    allow(@objects).to receive(:[]) { StringIO.new('aaa') }

    @ds = GoodData::Helpers::DataSource.new({
      type: :s3,
      bucket: 'some_bucket',
      key: 'some_key'
    })
  end

  it 'should be able to handle AWS' do
    expect(@ds.realized?).to be_falsey
    params = { 'aws_client' => { 's3_client' => @s3_client } }
    expect(@ds.realize(params)).to eq '2bdc6c8a02b2bd1d7997cf17f0848ecfcbceba25ca184e2676f19c054db7139b'
    expect(@ds.realized?).to be_truthy
  end

  it 'should gracefully handle missing aws client' do
    expect do
      @ds.realize({
        'aws_client' => nil
      })
    end.to raise_exception "AWS client not present. Perhaps S3Middleware is missing in the brick definition?"
  end

  it 'should gracefully handle missing data source params - bucket' do
    ds = GoodData::Helpers::DataSource.new({
      type: :s3,
      key: 'some_key'
    })
    params = { 'aws_client' => { 's3_client' => @s3_client } }
    expect do
      ds.realize(params)
    end.to raise_exception 'Key "bucket" is missing in S3 datasource'
  end

  it 'should gracefully handle missing data source params - key' do
    ds = GoodData::Helpers::DataSource.new({
      type: :s3,
      bucket: 'some_bucket'
    })
    params = { 'aws_client' => { 's3_client' => @s3_client } }
    expect do
      ds.realize(params)
    end.to raise_exception 'Key "key" is missing in S3 datasource'
  end
end