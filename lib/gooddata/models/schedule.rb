# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../rest/resource'
require_relative '../extensions/hash'
require_relative '../mixins/rest_resource'
require_relative '../helpers/global_helpers'

require_relative 'execution'

module GoodData
  class Schedule < Rest::Resource
    attr_reader :dirty, :json

    SCHEDULE_TEMPLATE = {
      :schedule => {
        :type => nil,
        :timezone => nil,
        :params => {},
        :hiddenParams => {},
        # :reschedule => nil
      }
    }

    class << self
      # Looks for schedule
      # @param id [String] URL, ID of schedule or :all
      # @return [GoodData::Schedule|Array<GoodData::Schedule>] List of schedules
      def [](id, opts = { :client => GoodData.connection, :project => GoodData.project })
        c, project = GoodData.get_client_and_project(opts)

        if id == :all
          GoodData::Schedule.all(opts)
        else
          if id =~ %r{\/gdc\/projects\/[a-zA-Z\d]+\/schedules\/?[a-zA-Z\d]*}
            url = id
            tmp = c.get url
            return c.create(GoodData::Schedule, tmp)
          end

          tmp = c.get "/gdc/projects/#{project.pid}/schedules/#{id}"
          c.create(GoodData::Schedule, tmp, project: project)
        end
      end

      # Returns list of all schedules for active project
      # @return [Array<GoodData::Schedule>] List of schedules
      def all(opts = { :client => GoodData.connection, :project => GoodData.project })
        c, project = GoodData.get_client_and_project(opts)

        tmp = c.get "/gdc/projects/#{project.pid}/schedules"
        tmp['schedules']['items'].map { |schedule| c.create(GoodData::Schedule, schedule, project: project) }
      end

      # Creates new schedules from parameters passed
      #
      # @param process_id [String] Process ID
      # @param trigger [String|GoodData::Schedule] Trigger of schedule. Can be cron string or reference to another schedule.
      # @param executable [String] Execution executable
      # @param options [Hash] Optional options
      # @return [GoodData::Schedule] New GoodData::Schedule instance
      def create(process_id, trigger, executable, options = {})
        c, project = GoodData.get_client_and_project(options)

        fail 'Process ID has to be provided' if process_id.blank?
        fail 'Executable has to be provided' if executable.blank?
        fail 'Trigger schedule has to be provided' if trigger.blank?

        schedule = c.create(GoodData::Schedule, GoodData::Helpers.deep_stringify_keys(GoodData::Helpers.deep_dup(SCHEDULE_TEMPLATE)), client: c, project: project)

        default_opts = {
          :type => 'MSETL',
          :timezone => 'UTC',
          :state => 'ENABLED',
          :params => {
            'PROCESS_ID' => process_id,
            'EXECUTABLE' => executable
          },
          # :reschedule => nil
        }

        schedule.name = options[:name]
        schedule.set_trigger(trigger)
        schedule.params = default_opts[:params].merge(options[:params] || {})
        schedule.hidden_params = options[:hidden_params] || {}
        schedule.timezone = options[:timezone] || default_opts[:timezone]
        schedule.state = options[:state] || default_opts[:state]
        schedule.schedule_type = options[:type] || default_opts[:type]
        schedule.reschedule = options[:reschedule] if options[:reschedule]
        schedule
      end
    end

    # Initializes object from raw json
    #
    # @param json [Object] Raw JSON
    # @return [GoodData::Schedule] New GoodData::Schedule instance
    def initialize(json)
      json = GoodData::Helpers.deep_stringify_keys(json)
      super
      @json = json
      self.params = GoodData::Helpers.decode_params(json['schedule']['params'] || {})
      self.hidden_params = GoodData::Helpers.decode_params(json['schedule']['hiddenParams'] || {})
    end

    def after
      project.schedules(trigger_id)
    end

    def after=(schedule)
      fail 'After trigger has to be a schedule object' unless schedule.is_a?(Schedule)
      json['schedule']['triggerScheduleId'] = schedule.obj_id
      @json['schedule']['cron'] = nil
      @dirty = true
    end

    # Deletes schedule
    def delete
      saved? ? client.delete(uri) : nil
    end

    # Is schedule enabled?
    #
    # @return [GoodData::Schedule]
    def disable
      @json['schedule']['state'] = 'DISABLED'
      @dirty = true
      self
    end

    # Is schedule enabled?
    #
    # @return [Boolean]
    def disable!
      disable
      save
    end

    # Is schedule disabled?
    #
    # @return [Boolean]
    def disabled?
      state == 'DISABLED'
    end

    # Is schedule enabled?
    #
    # @return [Boolean]
    def enabled?
      !disabled?
    end

    # Enables the schedule
    #
    # @return [GoodData::Schedule]
    def enable
      @json['schedule']['state'] = 'ENABLED'
      @dirty = true
      self
    end

    # Enables and saves the schedule
    #
    # @return [GoodData::Schedule]
    def enable!
      enable
      save
    end

    # Executes schedule
    #
    # @param [Hash] opts execution options.
    # @option opts [Boolean] :wait Wait for execution result
    # @return [Object] Raw Response
    def execute(opts = {})
      return nil unless saved?
      opts = { :wait => true }.merge(opts)
      data = {
        :execution => {}
      }
      res = client.post(execution_url, data)
      execution = client.create(GoodData::Execution, res, client: client, project: project)

      return execution unless opts[:wait]
      execution.wait_for_result(opts)
    end

    # Returns execution URL
    #
    # @return [String] Executions URL
    def execution_url
      saved? ? @json['schedule']['links']['executions'] : nil
    end

    # Returns execution state
    #
    # @return [String] Execution state
    def state
      @json['schedule']['state']
    end

    def state=(a_state)
      @json['schedule']['state'] = a_state
    end

    # Returns execution timezone
    #
    # @return [String] Execution timezone
    def timezone
      @json['schedule']['timezone']
    end

    # Assigns execution timezone
    #
    # @param new_timezone [String] Timezone to be set
    def timezone=(new_timezone)
      @json['schedule']['timezone'] = new_timezone
      @dirty = true
    end

    # Returns execution type
    #
    # @return [String] Execution type
    def type
      @json['schedule']['type']
    end

    # Assigns execution type
    #
    # @param new_type [String] Execution type to be set
    def type=(new_type)
      @json['schedule']['type'] = new_type
      @dirty = true
    end

    # Returns execution cron settings
    #
    # @return [String] Cron settings
    def cron
      @json['schedule']['cron']
    end

    # Assigns execution cron settings
    #
    # @param new_cron [String] Cron settings to be set
    def cron=(new_cron)
      @json['schedule']['cron'] = new_cron
      @json['schedule']['triggerScheduleId'] = nil
      @dirty = true
    end

    # Returns reschedule settings
    #
    # @return [Integer] Reschedule settings
    def reschedule
      @json['schedule']['reschedule']
    end

    # Assigns execution reschedule settings
    #
    # @param new_reschedule [Integer] Reschedule settings to be set
    def reschedule=(new_reschedule)
      @json['schedule']['reschedule'] = new_reschedule
      @dirty = true
    end

    # Returns execution process related to this schedule
    #
    # @return [GoodData::Process] Process ID
    def process
      project.processes(process_id)
    end

    # Returns execution process ID
    #
    # @return [String] Process ID
    def process_id
      @json['schedule']['params']['PROCESS_ID']
    end

    def process_id=(new_project_id)
      @json['schedule']['params']['PROCESS_ID'] = new_project_id
      @dirty = true
    end

    # Returns execution executable
    #
    # @return [String] Executable (graph) name
    def executable
      @json['schedule']['params']['EXECUTABLE']
    end

    # Assigns execution executable
    #
    # @param new_executable [String] Executable to be set.
    def executable=(new_executable)
      @json['schedule']['params']['EXECUTABLE'] = new_executable
      @dirty = true
    end

    # Returns enumerator of executions
    #
    # @return [Array] Raw Executions JSON
    def executions
      return nil unless @json
      url = @json['schedule']['links']['executions']
      Enumerator.new do |y|
        loop do
          res = client.get url
          res['executions']['paging']['next']
          res['executions']['items'].each do |execution|
            y << client.create(Execution, execution, :project => project)
          end
          url = res['executions']['paging']['next']
          break unless url
        end
      end
    end

    # Returns hidden_params as Hash
    #
    # @return [Hash] Hidden Parameters
    def hidden_params
      @json['schedule']['hiddenParams']
    end

    # Updates params by merging the current params with new ones
    #
    # @param params_to_merge [Hash] params
    # @return [GoodData::Schedule] Returns self
    def update_params(params_to_merge)
      params_to_merge.each do |k, v|
        set_parameter(k, v)
      end
      @dirty = true
      self
    end

    # Updates hidden params by merging the current params with new ones
    #
    # @param params_to_merge [Hash] params
    # @return [GoodData::Schedule] Returns self
    def update_hidden_params(params_to_merge)
      params_to_merge.each do |k, v|
        set_hidden_parameter(k, v)
      end
      @dirty = true
      self
    end

    # Assigns hidden parameters
    #
    # @param new_hidden_param [String] Hidden parameters to be set
    def hidden_params=(new_hidden_params = {})
      @json['schedule']['hiddenParams'] = new_hidden_params
      @dirty = true
      self
    end

    # Returns params as Hash
    #
    # @return [Hash] Parameters
    def params
      @json['schedule']['params']
    end

    # Assigns execution parameters
    #
    # @param params [String] Params to be set
    def params=(new_params = {})
      default_params = {
        'PROCESS_ID' => process_id,
        'EXECUTABLE' => executable
      }
      @json['schedule']['params'] = default_params.merge(new_params)
      @dirty = true
      self
    end

    # Saves object if dirty
    #
    # @return [Boolean] True if saved
    def save
      fail 'trigger schedule has to be provided' if cron.blank? && trigger_id.blank?
      fail 'A timezone has to be provided' if timezone.blank?
      fail 'Schedule type has to be provided' if schedule_type.blank?
      if @dirty
        if saved?
          res = client.put(uri, to_update_payload)
          @json = Schedule.new(res).json
        else
          res = client.post "/gdc/projects/#{project.pid}/schedules", to_update_payload
          fail 'Unable to create new schedule' if res.nil?
          new_obj_json = client.get res['schedule']['links']['self']
          @json = Schedule.new(new_obj_json).json
        end
        @dirty = false
      end
      self
    end

    # Updates params at key k with val v
    #
    # @param k [String] key
    # @param v [Object] value
    # @return [GoodData::Schedule] Returns self
    def set_parameter(k, v)
      params[k] = v
      @dirty = true
      self
    end

    # Updates hidden params at key k with val v
    #
    # @param k [String] key
    # @param v [Object] value
    # @return [GoodData::Schedule] Returns self
    def set_hidden_parameter(k, v)
      hidden_params[k] = v
      @dirty = true
      self
    end

    def schedule_type
      json['schedule']['type']
    end

    def schedule_type=(type)
      json['schedule']['type'] = type
      @dirty = true
      self
    end

    def time_based?
      cron != nil
    end

    def to_hash
      {
        name: name,
        type: type,
        state: state,
        params: params,
        hidden_params: hidden_params,
        cron: cron,
        trigger_id: trigger_id,
        timezone: timezone,
        uri: uri,
        reschedule: reschedule,
        executable: executable,
        process_id: process_id
      }
    end

    def trigger_id
      json['schedule']['triggerScheduleId']
    end

    def trigger_id=(a_trigger)
      json['schedule']['triggerScheduleId'] = a_trigger
      @dirty = true
      self
    end

    def name
      json['schedule']['name']
    end

    def name=(name)
      json['schedule']['name'] = name
      @dirty = true
      self
    end

    def set_trigger(trigger) # rubocop:disable Style/AccessorMethodName
      if trigger.is_a?(String) && trigger =~ /[a-fA-Z0-9]{24}/
        self.trigger_id = trigger
      elsif trigger.is_a?(GoodData::Schedule)
        self.trigger_id = trigger.obj_id
      else
        self.cron = trigger
      end
    end

    # Returns URL
    #
    # @return [String] Schedule URL
    def uri
      @json['schedule']['links']['self'] if @json && @json['schedule'] && @json['schedule']['links']
    end

    def ==(other)
      other.respond_to?(:uri) && other.uri == uri && other.respond_to?(:to_hash) && other.to_hash == to_hash
    end

    def to_update_payload
      res = {
        'schedule' => {
          'name' => name,
          'type' => type,
          'state' => state,
          'timezone' => timezone,
          'cron' => cron,
          'triggerScheduleId' => trigger_id,
          'params' => GoodData::Helpers.encode_public_params(params),
          'hiddenParams' => GoodData::Helpers.encode_hidden_params(hidden_params)
        }
      }

      res['schedule']['reschedule'] = reschedule if reschedule

      res
    end
  end
end
