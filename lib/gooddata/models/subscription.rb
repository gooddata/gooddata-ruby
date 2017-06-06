# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../mixins/rest_resource'

module GoodData
  class Subscription < Rest::Resource
    SUBSCRIPTION_PATH = '/gdc/projects/%s/users/%s/subscriptions'

    EMPTY_OBJECT = {
      'subscription' => {
        'triggers' => [],
        'condition' => {
          'condition' => {
            'expression' => 'true'
          }
        },
        'message' => {
          'template' => {
            'expression' => ''
          }
        },
        'subject' => {
          'template' => {
            'expression' => ''
          }
        },
        'channels' => [],
        'meta' => {
          'title' => ''
        }
      }
    }

    set_const :PROCESS_SCHEDULED_EVENT, 'dataload.process.schedule'
    set_const :PROCESS_STARTED_EVENT, 'dataload.process.start'
    set_const :PROCESS_SUCCESS_EVENT, 'dataload.process.finish.ok'
    set_const :PROCESS_FAILED_EVENT, 'dataload.process.finish.error'

    attr_accessor :title, :process, :channels, :message, :subject, :project_events, :timer_event

    class << self
      def [](id = :all, opts = { client: GoodData.connection })
        c = GoodData.get_client(opts)
        pid = (opts[:project].respond_to?(:pid) && opts[:project].pid) || opts[:project]
        uri = SUBSCRIPTION_PATH % [pid, c.user.account_setting_id]
        if id == :all
          data = c.get uri
          data['subscriptions']['items'].map { |subscription_data| c.create(Subscription, subscription_data, project: pid) }
        else
          c.create(Subscription, c.get("#{uri}/#{id}"), project: pid)
        end
      end

      def all(opts = { client: GoodData.connection })
        Subscription[:all, opts]
      end

      def create(opts = { client: GoodData.connection })
        c = GoodData.get_client(opts)

        [:project, :channels, :process, :project_events].each { |key| fail "No #{key.inspect} specified" unless opts[key] }

        pid = (opts[:project].respond_to?(:pid) && opts[:project].pid) || opts[:project]
        project_events = (opts[:project_events].respond_to?(:each) && opts[:project_events]) || [opts[:project_events]]

        process_id = (opts[:process].respond_to?(:process_id) && opts[:process].process_id) || opts[:process]
        condition = "params.PROCESS_ID=='#{process_id}'"

        channels = (opts[:channels].respond_to?(:each) && opts[:channels]) || [opts[:channels]]
        channel_uris = channels.map { |channel| channel.respond_to?(:uri) && channel.uri || channel }

        options = { message: 'Email body', subject: 'Email subject', title: c.user.email }.merge(opts)
        subscription = create_object(options.merge(channels: channel_uris, project_events: project_events, condition: condition, project: pid))
        subscription.save
        subscription
      end

      def create_object(data = {})
        c = GoodData.get_client(data)

        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['subscription']['condition']['condition']['expression'] = data[:condition]
          d['subscription']['message']['template']['expression'] = data[:message]
          d['subscription']['subject']['template']['expression'] = data[:subject]
          d['subscription']['meta']['title'] = data[:title]
          d['subscription']['channels'] = data[:channels]

          triggers = []
          triggers << {
            'projectEventTrigger' => {
              'types' => data[:project_events]
            }
          }
          if data[:timer_event]
            triggers << {
              'timerEvent' => {
                'cronExpression' => data[:timer_event]
              }
            }
          end
          d['subscription']['triggers'] = triggers
        end

        c.create(Subscription, new_data, data)
      end
    end

    # Initializes object instance from raw wire JSON
    #
    # @param json Json used for initialization
    def initialize(json)
      super
      @json = json

      @title = data['meta']['title']
      @message = data['message']['template']['expression']
      @subject = data['subject']['template']['expression']
      @process = data['condition']['condition']['expression'][/'(.*)'/, 1]
      @channels = data['channels']
      @project_events = data['triggers'].find { |h| h.keys.first == 'projectEventTrigger' }['projectEventTrigger']['types']

      timer_events = data['triggers'].select { |h| h.keys.first == 'timerEvent' }
      timer_events && @timer_events = timer_events.map { |_, v| v }
    end

    def save
      response = if uri
                  data_to_send = GoodData::Helpers.deep_dup(raw_data).tap do |d|
                    d['subscription']['condition']['condition']['expression'] = "params.PROCESS_ID=='#{(process.respond_to?(:process_id) && process.process_id) || process}'"
                    d['subscription']['message']['template']['expression'] = message
                    d['subscription']['subject']['template']['expression'] = subject
                    d['subscription']['meta']['title'] = title
                    d['subscription']['channels'] = ((channels.respond_to?(:each) && channels) || [channels]).map { |channel| channel.respond_to?(:uri) && channel.uri || channel }

                    triggers = []
                    triggers << {
                      'projectEventTrigger' => {
                        'types' => (project_events.respond_to?(:each) && project_events) || [project_events]
                      }
                    }
                    if timer_event
                      triggers << {
                        'timerEvent' => {
                          'cronExpression' => timer_event
                        }
                      }
                    end
                    d['subscription']['triggers'] = triggers
                  end
                  client.put(uri, data_to_send)
                else
                  client.post(SUBSCRIPTION_PATH % [project, client.user.account_setting_id], raw_data)
                end
      @json = client.get response['subscription']['meta']['uri']
      self
    end

    def uri
      data['meta']['uri'] if data && data['meta'] && data['meta']['uri']
    end

    def obj_id
      uri.split('/').last
    end

    alias_method :subscription_id, :obj_id

    def delete
      client.delete uri
    end

    def ==(other)
      return false unless [:project, :title, :process, :channels, :message, :subject, :project_events, :timer_event].all? { |m| other.respond_to?(m) }
      @project == other.project &&
        @title == other.title &&
        @process == other.process &&
        @channels == other.channels &&
        @message == other.message &&
        @subject == other.subject &&
        @project_events == other.project_events &&
        @timer_event == other.timer_event
    end
  end
end
