# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'scheduled_mail/dashboard_attachment'
require_relative 'scheduled_mail/report_attachment'

require_relative '../../helpers/global_helpers'

require_relative '../../core/core'
require_relative '../metadata'
require_relative 'metadata'
require_relative 'report'

require 'multi_json'

module GoodData
  class ScheduledMail < GoodData::MdObject
    root_key :scheduledMail

    include GoodData::Mixin::Lockable

    DEFAULT_OPTS = {
      # Meta options
      :title => 'Scheduled report example',
      :summary => 'Daily at 12:00pm PT',
      :tags => '',
      :deprecated => 0,

      # Content When options
      :recurrency => '0:0:0:12:0:0',
      :startDate => '2012-06-05',
      :timeZone => 'America/Los_Angeles',

      # Content Email options
      :to => [],
      :bcc => [],
      :subject => 'Scheduled Report',
      :body => "Hey, I'm sending you new Reports and Dashboards!",

      # Attachments
      :attachments => []
    }

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('scheduledMail', ScheduledMail, options)
      end

      def convert_attachment(item, opts)
        if item.is_a?(GoodData::Dashboard)
          {
            dashboardAttachment: GoodData::DashboardAttachment::DEFAULT_OPTS.merge(opts.merge(:uri => item.uri))
          }
        elsif item.is_a?(GoodData::Report)
          {
            reportAttachment: GoodData::ReportAttachment::DEFAULT_OPTS.merge(opts.merge(:uri => item.uri))
          }
        elsif item.is_a?(GoodData::DashboardAttachment)
          item.json
        elsif item.is_a?(GoodData::ReportAttachment)
          item.json
        elsif item.is_a?(Hash)
          item
        elsif item == 'dashboardAttachment'
          {
            dashboardAttachment: GoodData::DashboardAttachment::DEFAULT_OPTS.merge(opts)
          }
        elsif item == 'reportAttachment'
          {
            reportAttachment: GoodData::ReportAttachment::DEFAULT_OPTS.merge(opts)
          }
        end
      end

      def create(options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = client.projects(p)
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        opts = GoodData::ScheduledMail::DEFAULT_OPTS.merge(GoodData::Helpers.symbolize_keys(options))

        scheduled_mail = {
          :scheduledMail => {
            :meta => {
              :title => opts[:title],
              :summary => opts[:summary],
              :tags => opts[:tags],
              :deprecated => opts[:deprecated]
            },
            :content => {
              :when => {
                :recurrency => opts[:recurrency],
                :startDate => opts[:startDate] || opts[:start_date],
                :timeZone => opts[:timeZone] || opts[:time_zone] || opts[:timezone]
              },
              :to => opts[:to].is_a?(Array) ? opts[:to] : [opts[:to]],
              :bcc => opts[:bcc].is_a?(Array) ? opts[:bcc] : [opts[:bcc]],
              :subject => opts[:subject],
              :body => opts[:body]
            }
          }
        }

        attachments = opts[:attachments].map do |attachment|
          key = attachment.keys.first
          body = attachment[key]

          ScheduledMail.convert_attachment(key, body)
        end

        scheduled_mail[:scheduledMail][:content][:attachments] = attachments

        client.create(ScheduledMail, GoodData::Helpers.deep_stringify_keys(scheduled_mail), :project => project)
      end
    end

    # Add attachment
    #
    # @param [String | Object] item Schedule to add
    # @param [Hash] opts Optional schedule options
    # @return [Array] New list of attachments
    def add_attachment(item, opts)
      attachment = ScheduledMail.convert_attachment(item, opts)
      fail ArgumentError unless attachment

      content['attachments'] << attachment
    end

    # Add attachment and save
    #
    # @param [String | Object] item Schedule to add
    # @param [Hash] opts Optional schedule options
    # @return [Array] New list of attachments
    def add_attachment!(item, opts)
      add_attachment(item, opts)
      save!
    end

    # Get attachments as objects
    #
    # @return [Array<GoodData::DashboardAttachment | GoodData::ReportAttachment>] Array of attachments
    def attachments
      content['attachments'].map do |attachment|
        key = attachment.keys.first

        if key == 'dashboardAttachment'
          GoodData::DashboardAttachment.new(self, attachment)
        elsif key == 'reportAttachment'
          GoodData::ReportAttachment.new(self, attachment)
        else
          RuntimeError "Unsupported attachment type: #{key}"
        end
      end
    end

    # Get body
    #
    # @return [String] Scheduled email body
    def body
      content['body']
    end

    # Set body
    #
    # @param [String] new_body New body to be set
    # @return [String] New body
    def body=(new_body)
      content['body'] = new_body
    end

    # Get recurrency string
    #
    # @return [String] Recurrency (cron) string
    def recurrency
      content['when']['recurrency']
    end

    # Set recurrency
    #
    # @param [String] new_recurrency New recurrency to be set
    # @return [Hash] New recurrency
    def recurrency=(new_recurrency)
      content['when']['recurrency'] = new_recurrency
    end

    # Get start date
    #
    # @return [String] Start date
    def start_date
      content['when']['startDate']
    end

    # Set start date
    #
    # @param [String] new_start_date New start date to be set
    # @return [String] New start date
    def start_date=(new_start_date)
      content['when']['startDate'] = new_start_date
    end

    # Get subject
    #
    # @return [String] Subject of scheduled email
    def subject
      content['subject']
    end

    # Set subject
    #
    # @param [String] new_subject New subject to be set
    # @return [String] New subject
    def subject=(new_subject)
      content['subject'] = new_subject
    end

    # Get timezone
    #
    # @return [String] Timezone
    def timezone
      content['when']['timeZone']
    end

    # Set timezone
    #
    # @param [String] new_timezone New timezone string to be set
    # @return [String] New timezone
    def timezone=(new_timezone)
      content['when']['timeZone'] = new_timezone
    end

    # Get recipients
    #
    # @return [String] Recipients of email
    def to
      content['to']
    end

    # Set recipients
    #
    # @param [String|Array<String>] new_to New recipients to be set
    # @return [Array<String>] New recipient list
    def to=(new_to)
      content['to'] = new_to.is_a?(Array) ? new_to : [new_to]
    end

    # Get 'when' section
    #
    # @return [Hash] 'when' section from json
    def when
      content['when']
    end

    # Set 'when' section
    #
    # @param [Hash] new_when New 'when' section to be set
    # @return [Hash] New 'when' section
    def when=(new_when)
      content['when'] = new_when
    end
  end
end
