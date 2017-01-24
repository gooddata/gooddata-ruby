# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class ChannelConfiguration < Rest::Resource
    CHANNEL_CONFIGURATION_PATH = '/gdc/account/profile/%s/channelConfigurations'

    EMPTY_OBJECT = {
      'channelConfiguration' => {
        'configuration' => {
          'emailConfiguration' => {
            'to' => ''
          }
        },
        'meta' => {
          'title' => ''
        }
      }
    }

    attr_accessor :title, :to

    class << self
      def [](id = :all)
        uri = CHANNEL_CONFIGURATION_PATH % client.user.account_setting_id
        if id == :all
          data = client.get uri
          data['channelConfigurations']['items'].map { |channel_data| client.create(ChannelConfiguration, channel_data) }
        else
          client.create(ChannelConfiguration, client.get("#{uri}/#{id}"))
        end
      end

      def all
        ChannelConfiguration[:all]
      end

      def create(opts = { client: GoodData.connection })
        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        options = { to: c.user.email, title: c.user.email }.merge(opts)
        existing_channel = all.find { |channel| channel.to == options[:to] }
        return existing_channel if existing_channel

        channel = create_object(options)
        channel.save
        channel
      end

      def create_object(data = {})
        c = client(data)

        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['channelConfiguration']['configuration']['emailConfiguration']['to'] = data[:to]
          d['channelConfiguration']['meta']['title'] = data[:title]
        end

        c.create(ChannelConfiguration, new_data)
      end
    end

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      super
      @json = json
      @to = data['configuration']['emailConfiguration']['to']
      @title = data['meta']['title']
    end

    def save
      response = if uri
                   data_to_send = GoodData::Helpers.deep_dup(raw_data).tap do |d|
                     d['channelConfiguration']['configuration']['emailConfiguration']['to'] = to
                     d['channelConfiguration']['meta']['title'] = title
                   end
                   client.put(uri, data_to_send)
                 else
                   client.post(CHANNEL_CONFIGURATION_PATH % client.user.account_setting_id, raw_data)
                 end
      @json = client.get response['channelConfiguration']['meta']['uri']
      self
    end

    def delete
      client.delete uri
    end

    def uri
      data['meta']['uri'] if data && data['meta'] && data['meta']['uri']
    end

    def obj_id
      uri.split('/').last
    end

    alias_method :channel_id, :obj_id

    def ==(other)
      return false unless [:to, :title].all? { |m| other.respond_to?(m) }
      @to == other.to && @title == other.title
    end
  end
end
