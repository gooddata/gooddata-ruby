# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/aws_middleware'

describe GoodData::Bricks::AWSMiddleware do
  subject { GoodData::Bricks::AWSMiddleware.new(app: proc {}) }

  context 'when aws_client config' do
    it 'should do nothing if the key "aws_client" is not there at all' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: ->(_params) { 'Doing nothing' })
      middleware.call({})
    end

    it 'should fail gracefully if value aws_client param not present even though the key is' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('aws_client' => nil)
      end.to raise_exception 'Unable to connect to AWS. Parameter "aws_client" seems to be empty'
    end

    it 'should fail gracefully if value secret_access_key is missing' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('aws_client' => { 'access_key_id' => 'something' })
      end.to raise_exception 'Unable to connect to AWS. Parameter "secret_access_key" is missing'
    end

    it 'should fail gracefully if value access_key_id is missing' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('aws_client' => { 'secret_access_key' => 'something' })
      end.to raise_exception 'Unable to connect to AWS. Parameter "access_key_id" is missing'
    end

    it "should prepare aws middleware for aws_client param" do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda do |params|
        expect(params['s3_client']['client']).to be_kind_of(Aws::S3::Resource)
      end)
      middleware.call('aws_client' => { 'secret_access_key' => 'something', 'access_key_id' => 'something' })
    end
  end

  context 'when s3_client config' do
    it 'should do nothing if the key "s3_client" is not there at all' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: ->(_params) { 'Doing nothing' })
      middleware.call({})
    end

    it 'should fail gracefully if value s3_client param not present even though the key is' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('s3_client' => nil)
      end.to raise_exception 'Unable to connect to AWS. Parameter "s3_client" seems to be empty'
    end

    it 'should fail gracefully if value secretKey is missing' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('s3_client' => { 'accessKey' => 'something' })
      end.to raise_exception 'Unable to connect to AWS. Parameter "secretKey" is missing'
    end

    it 'should fail gracefully if value accessKey is missing' do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: -> { 'Doing nothing' })
      expect do
        middleware.call('s3_client' => { 'secretKey' => 'something' })
      end.to raise_exception 'Unable to connect to AWS. Parameter "accessKey" is missing'
    end

    it "should prepare aws middleware for aws_client param" do
      middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda do |params|
        expect(params['s3_client']['client']).to be_kind_of(Aws::S3::Resource)
      end)
      middleware.call('s3_client' => { 'secretKey' => 'something', 'accessKey' => 'something', 'bucket' => 'something' })
    end
  end

  context 'when use_ssl parameter specified' do
    let(:params) do
      {
        'aws_client' => {
          'access_key_id' => 'foo',
          'secret_access_key' => 'bar',
          'region' => 'baz',
          'use_ssl' => 'false'
        }
      }
    end

    it 'raises an error' do
      expect { subject.call(params) }.to raise_error(/use_ssl has been deprecated/)
    end
  end

  context 'when a superfluous parameter is specified' do
    let(:params) do
      {
        'aws_client' => {
          'access_key_id' => 'foo',
          'secret_access_key' => 'bar',
          'region' => 'baz',
          'qux' => 'quux'
        }
      }
    end

    it 'raises an error' do
      expect { subject.call(params) }.to raise_error(ArgumentError, /qux/)
    end
  end

  context 'when region not specified' do
    let(:params) do
      {
        'aws_client' => {
          'access_key_id' => 'foo',
          'secret_access_key' => 'bar'
        }
      }
    end

    it 'it defaults to us-west-2' do
      expect(Aws::S3::Resource).to receive(:new) do |params|
        expect(params[:region]).to eq 'us-west-2'
      end
      subject.call(params)
    end
  end
end
