# encoding: UTF-8

require 'gooddata/bricks/brick'
require 'gooddata/bricks/bricks'
require 'gooddata/bricks/middleware/aws_middleware'

describe GoodData::Bricks::AWSMiddleware do
  it 'should do nothing if the key "aws_client" is not there at all' do
    middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda {|params| 'Doing nothing'})
    middleware.call({})
  end

  it 'should fail gracefully if value aws_client param not present even though the key is' do
    middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda {|params| 'Doing nothing'})
    expect do
      middleware.call('aws_client' => nil)
    end.to raise_exception 'Unable to connect to AWS. Parameter "aws_client" seems to be empty'
  end

  it 'should fail gracefully if value secret_access_key is missing' do
    middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda {|params| 'Doing nothing'})
    expect do
      middleware.call('aws_client' => {
        'access_key_id' => 'something'
      })
    end.to raise_exception 'Unable to connect to AWS. Parameter "secret_access_key" is missing'
  end

  it 'should fail gracefully if value access_key_id is missing' do
    middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda {|params| 'Doing nothing'})
    expect do
      middleware.call('aws_client' => {
        'secret_access_key' => 'something'
      })
    end.to raise_exception 'Unable to connect to AWS. Parameter "access_key_id" is missing'
  end

  it "should preapre aws middleware for aws_client param" do
    middleware = GoodData::Bricks::AWSMiddleware.new(app: lambda do |params|
      expect(params['aws_client']['s3_client']).to be_kind_of(AWS::S3)
    end)
    middleware.call('aws_client' => {
      'secret_access_key' => 'something',
      'access_key_id' => 'something'
    })
  end
end
