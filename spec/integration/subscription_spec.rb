# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

require_relative '../lcm/integration/support/comparison_helper'

describe GoodData::Subscription, :vcr, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @channel = GoodData::ChannelConfiguration.create(client: @client)
    subscriptions = GoodData::Subscription.all(project: ProjectHelper.project_id(@client), client: @client)
    subscriptions.each(&:delete)
  end

  after(:all) do
    @channel && @channel.delete
    @client && @client.disconnect
  end

  it 'should be able to create a subscription' do
    begin
      subscription = GoodData::Subscription.create(
        client: @client,
        project: ProjectHelper.project_id(@client),
        channels: @channel,
        message: 'hello world',
        process: ProjectHelper.process_id(@client),
        project_events: GoodData::Subscription::PROCESS_SUCCESS_EVENT
      )
      expect(subscription.title).to eq ConnectionHelper::DEFAULT_USERNAME
      expect(subscription.channels).to eq [@channel.uri]
      expect(subscription.message).to eq 'hello world'
      expect(subscription.process).to eq ProjectHelper.process_id(@client)
      expect(subscription.project_events).to eq [GoodData::Subscription::PROCESS_SUCCESS_EVENT]
    ensure
      subscription && subscription.delete
    end
  end

  it 'should be able to edit a subscription' do
    begin
      subscription = GoodData::Subscription.create(
        client: @client,
        project: ProjectHelper.project_id(@client),
        channels: @channel,
        process: ProjectHelper.process_id(@client),
        project_events: GoodData::Subscription::PROCESS_SUCCESS_EVENT
      )
      expect(subscription.title).to eq ConnectionHelper::DEFAULT_USERNAME

      subscription.title = 'My title'
      subscription.save

      expect(GoodData::Subscription[subscription.subscription_id, project: ProjectHelper.project_id(@client), client: @client].title).to eq 'My title'
    ensure
      subscription && subscription.delete
    end
  end

  it 'should be able to list all subscriptions' do
    begin
      expect(GoodData::Subscription.all(project: ProjectHelper.project_id(@client), client: @client)).to eq []
      subscription = GoodData::Subscription.create(
        client: @client,
        project: ProjectHelper.project_id(@client),
        channels: @channel,
        process: ProjectHelper.process_id(@client),
        project_events: GoodData::Subscription::PROCESS_SUCCESS_EVENT
      )
      diff = Support::ComparisonHelper.compare_subscriptions(GoodData::Subscription.all(project: ProjectHelper.project_id(@client), client: @client).first, subscription)
      expect(diff).to be_empty
    ensure
      subscription && subscription.delete
    end
  end

  it 'should be able to delete a subscription' do
    subscription = GoodData::Subscription.create(
      client: @client,
      project: ProjectHelper.project_id(@client),
      channels: @channel,
      process: ProjectHelper.process_id(@client),
      project_events: GoodData::Subscription::PROCESS_SUCCESS_EVENT
    )
    subscription.delete
  end
end
