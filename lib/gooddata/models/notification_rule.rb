# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

module GoodData
  class NotificationRule < Rest::Resource
    NOTIFICATION_RULES_PATH = '/gdc/projects/%s/dataload/processes/%s/notificationRules'

    EMPTY_OBJECT = {
      'notificationRule' => {
        'email' => '',
        'subject' => '',
        'body' => '',
        'events' => []
      }
    }

    attr_accessor :email, :subject, :body, :events, :process
    attr_reader :subscription, :channels

    class << self
      def [](id = :all, opts = {})
        pid = (opts[:project].respond_to?(:pid) && opts[:project].pid) || opts[:project]
        process_id = (opts[:process].respond_to?(:process_id) && opts[:process].process_id) || opts[:process]
        uri = NOTIFICATION_RULES_PATH % [pid, process_id]
        if id == :all
          data = client.get uri
          data['notificationRules']['items'].map { |notification_data| client.create(NotificationRule, notification_data) }
        else
          client.create(NotificationRule, client.get("#{uri}/#{id}"))
        end
      end

      def all(opts = {})
        NotificationRule[:all, opts]
      end

      def create(opts = {})
        c = client(opts)
        fail ArgumentError, 'No :client specified' unless c
        [:email, :events, :project, :process].each { |key| fail "No #{key.inspect} specified" unless opts[key] }

        pid = (opts[:project].respond_to?(:pid) && opts[:project].pid) || opts[:project]
        process_id = (opts[:process].respond_to?(:process_id) && opts[:process].process_id) || opts[:process]
        events = (opts[:events].respond_to?(:each) && opts[:events]) || [opts[:events]]

        notification_rule = create_object({ subject: 'Email subject', body: 'Email body' }.merge(opts).merge(project: pid, process: process_id, events: events))
        notification_rule.save
        notification_rule
      end

      def create_object(data = {})
        c = client(data)

        new_data = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
          d['notificationRule']['email'] = data[:email]
          d['notificationRule']['subject'] = data[:subject]
          d['notificationRule']['body'] = data[:body]
          d['notificationRule']['events'] = data[:events]
        end

        c.create(NotificationRule, new_data, data)
      end
    end

    def initialize(json)
      super
      @json = json

      @email = data['email']
      @subject = data['subject']
      @body = data['body']
      @events = data['events']
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
    end

    def obj_id
      uri.split('/').last
    end

    alias_method :notification_rule_id, :obj_id

    def save
      response = if uri
                   data_to_send = GoodData::Helpers.deep_dup(EMPTY_OBJECT).tap do |d|
                     d['notificationRule']['email'] = email
                     d['notificationRule']['subject'] = subject
                     d['notificationRule']['body'] = body
                     d['notificationRule']['events'] = (events.respond_to?(:each) && events) || events
                   end
                   client.put(uri, data_to_send)
                 else
                   client.post(NOTIFICATION_RULES_PATH % [project, process], raw_data)
                 end
      @json = client.get response['notificationRule']['links']['self']
      @subscription = data['links']['subscription']
      @channels = data['links']['channels']
    end

    def ==(other)
      return false unless [:email, :subject, :body, :events].all? { |m| other.respond_to?(m) }
      @email == other.email && @subject == other.subject && @body == other.body && @events == other.events
    end

    def delete
      client.delete uri
    end
  end
end
