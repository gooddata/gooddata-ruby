# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/rest/rest'

describe 'Behavior during polling and retries' do
  before :each do
    WebMock.enable!

    @server = GoodData::Environment::ConnectionHelper::DEFAULT_SERVER
    @coef = GoodData::Rest::Connection::RETRY_TIME_COEFFICIENT
    @init = GoodData::Rest::Connection::RETRY_TIME_INITIAL_VALUE
    @poll = GoodData::Rest::Client::DEFAULT_SLEEP_INTERVAL

    GoodData::Rest::Connection.send(:remove_const, :RETRY_TIME_COEFFICIENT) if GoodData::Rest::Connection.const_defined?(:RETRY_TIME_COEFFICIENT)
    GoodData::Rest::Connection.send(:remove_const, :RETRY_TIME_INITIAL_VALUE) if GoodData::Rest::Connection.const_defined?(:RETRY_TIME_INITIAL_VALUE)
    GoodData::Rest::Client.send(:remove_const, :DEFAULT_SLEEP_INTERVAL) if GoodData::Rest::Client.const_defined?(:DEFAULT_SLEEP_INTERVAL)

    GoodData::Rest::Connection.const_set(:RETRY_TIME_COEFFICIENT, 1)
    GoodData::Rest::Connection.const_set(:RETRY_TIME_INITIAL_VALUE, 0)
    GoodData::Rest::Client.const_set(:DEFAULT_SLEEP_INTERVAL, 0)
    stub_request(:get, "#{@server}/gdc")
      .to_return(:body => {"about" => { "links" => [{ "link"=>"https://secure-di.gooddata.com/uploads", "summary"=>"User data staging area.", "category"=>"uploads", "title"=>"user-uploads" }]}}.to_json, :headers => { 'Content-Type' => "application/json" })
    stub_request(:post, "#{@server}/gdc/account/login")
      .to_return(:body => { :userLogin => { :profile => "/profile/123" }}.to_json, :headers => { 'Content-Type' => "application/json" })
    stub_request(:get, "#{@server}/gdc/account/token")
      .to_return(:body => {}.to_json, :headers => { 'Content-Type' => "application/json" })
    stub_request(:get, "#{@server}/profile/123")
      .to_return(:body => {}.to_json, :headers => { 'Content-Type' => "application/json" })
    stub_request(:get, "#{@server}/poll_test")
      .to_return(:body => {stuff: :aaa}.to_json, :headers => { 'Content-Type' => "application/json"} )
    stub_request(:get, "#{@server}/too_many_reqs")
      .to_return(:body => {}.to_json, :status => 429, :headers => { 'Content-Type' => "application/json"} )
    stub_request(:get, "#{@server}/out_of_service")
      .to_return(:body => {}.to_json, :status => 503, :headers => { 'Content-Type' => "application/json"} )
    stub_request(:get, "#{@server}/internal_error")
      .to_return(:body => {}.to_json, :status => 500, :headers => { 'Content-Type' => "application/json"} )

    @client = GoodData.connect('aaa', 'bbbb')
  end

  after :each do
    WebMock.disable!
    GoodData::Rest::Connection.send(:remove_const, :RETRY_TIME_COEFFICIENT) if GoodData::Rest::Connection.const_defined?(:RETRY_TIME_COEFFICIENT)
    GoodData::Rest::Connection.send(:remove_const, :RETRY_TIME_INITIAL_VALUE) if GoodData::Rest::Connection.const_defined?(:RETRY_TIME_INITIAL_VALUE)
    GoodData::Rest::Client.send(:remove_const, :DEFAULT_SLEEP_INTERVAL) if GoodData::Rest::Client.const_defined?(:DEFAULT_SLEEP_INTERVAL)

    GoodData::Rest::Connection.const_set(:RETRY_TIME_COEFFICIENT, @coef)
    GoodData::Rest::Connection.const_set(:RETRY_TIME_INITIAL_VALUE, @init)
    GoodData::Rest::Client.const_set(:DEFAULT_SLEEP_INTERVAL, @poll)
  end

  it 'should fail a poller after timelimit passes' do
    expect do
      @client.poll_on_response('/poll_test', time_limit: 0.1) { |_| true }
    end.to raise_error(GoodData::ExecutionLimitExceeded)
  end

  it 'should make MAX_REQUESTS when hitting 429' do
    expect do
      @client.get('/too_many_reqs')
    end.to raise_error(RestClient::TooManyRequests)
    expect(a_request(:get, "#{@server}/too_many_reqs")).to have_been_made.times(12)
  end

  it 'should make MAX_REQUESTS when hitting 503' do
    expect do
      @client.get('/out_of_service')
    end.to raise_error(RestClient::ServiceUnavailable)
    expect(a_request(:get, "#{@server}/out_of_service")).to have_been_made.times(12)
  end

  it 'should make 1 additional request when hitting 500' do
    expect do
      @client.get('/internal_error')
    end.to raise_error(RestClient::InternalServerError)
    expect(a_request(:get, "#{@server}/internal_error")).to have_been_made.times(3)
  end

  it 'Number of requests can be overriden' do
    expect do
      @client.get('/internal_error', :tries => 4)
    end.to raise_error(RestClient::InternalServerError)
    expect(a_request(:get, "#{@server}/internal_error")).to have_been_made.times(4)
  end
end
