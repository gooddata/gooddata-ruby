# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe GoodData::ChannelConfiguration, :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
  end

  after(:all) do
    @client.disconnect
  end

  it 'should be able to create a channel' do
    begin
      channel = GoodData::ChannelConfiguration.create(client: @client)
      expect(channel.to).to eq ConnectionHelper::DEFAULT_USERNAME
      expect(channel.title).to eq ConnectionHelper::DEFAULT_USERNAME
    ensure
      channel && channel.delete
    end
  end

  it 'should not create dubplicate channel' do
    begin
      channel = GoodData::ChannelConfiguration.create(client: @client)
      GoodData::ChannelConfiguration.create(client: @client, title: 'another channel')
      expect(GoodData::ChannelConfiguration.all).to eq [channel]
    ensure
      channel && channel.delete
    end
  end

  it 'should be able to edit a channel' do
    begin
      channel = GoodData::ChannelConfiguration.create(client: @client, title: 'my channel')
      expect(channel.to).to eq ConnectionHelper::DEFAULT_USERNAME
      expect(channel.title).to eq 'my channel'

      channel.title = 'New title'
      channel.save

      expect(GoodData::ChannelConfiguration[channel.channel_id].title).to eq 'New title'
    ensure
      channel && channel.delete
    end
  end

  it 'should be able to list all channels' do
    begin
      expect(GoodData::ChannelConfiguration.all).to eq []
      channel = GoodData::ChannelConfiguration.create(client: @client)
      expect(GoodData::ChannelConfiguration.all).to eq [channel]
    ensure
      channel && channel.delete
    end
  end

  it 'should be able to delete a channel' do
    channel = GoodData::ChannelConfiguration.create(client: @client)
    channel.delete
  end
end
