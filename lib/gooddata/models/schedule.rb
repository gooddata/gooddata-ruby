# encoding: UTF-8

require_relative '../rest/resource'
require_relative '../extensions/hash'
require_relative '../mixins/rest_resource'
require_relative '../helpers/global_helpers'

require_relative 'execution'

module GoodData
  class Schedule < Rest::Resource
    attr_reader :dirty, :json

    alias_method :data, :json
    alias_method :raw_data, :json
    alias_method :to_hash, :json

    include GoodData::Mixin::RestResource
    root_key :schedule

    class << self
      # Looks for schedule
      # @param id [String] URL, ID of schedule or :all
      # @return [GoodData::Schedule|Array<GoodData::Schedule>] List of schedules
      def [](id, opts = { :client => GoodData.connection, :project => GoodData.project })
        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

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
        c = client(opts)
        fail ArgumentError, 'No :client specified' if c.nil?

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

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
        c = client(options)
        fail ArgumentError, 'No :client specified' if c.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        default_opts = {
          :type => 'MSETL',
          :timezone => 'UTC',
          :params => {
            :PROCESS_ID => process_id,
            :EXECUTABLE => executable
          },
          :hiddenParams => {},
          :reschedule => options[:reschedule] || 0
        }

        if trigger =~ /[a-fA-Z0-9]{24}/
          default_opts[:triggerScheduleId] = trigger
        elsif trigger.is_a?(GoodData::Schedule)
          default_opts[:triggerScheduleId] = trigger.obj_id
        else
          default_opts[:cron] = trigger
        end

        if options.key?(:hidden_params)
          options[:hiddenParams] = options[:hidden_params]
          options.delete :hidden_params
        end

        json = {
          'schedule' => default_opts.deep_merge(options.except(:project, :client))
        }

        tmp = json['schedule'][:params][:PROCESS_ID]
        fail 'Process ID has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:params][:EXECUTABLE]
        fail 'Executable has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:cron] || json['schedule'][:triggerScheduleId]
        fail 'trigger schedule has to be provided' if !tmp || tmp.nil? || tmp.empty?

        tmp = json['schedule'][:timezone]
        fail 'A timezone has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:type]
        fail 'Schedule type has to be provided' if tmp.nil? || tmp.empty?

        params = json['schedule'][:params]
        params = GoodData::Helpers.encode_params(params, false)
        json['schedule'][:params] = params

        hidden_params = json['schedule'][:hiddenParams]
        if hidden_params && !hidden_params.empty?
          hidden_params = GoodData::Helpers.encode_params(json['schedule'][:hiddenParams], true)
          json['schedule'][:hiddenParams] = hidden_params
        end

        url = "/gdc/projects/#{project.pid}/schedules"
        res = c.post url, json

        fail 'Unable to create new schedule' if res.nil?

        new_obj_json = c.get res['schedule']['links']['self']
        c.create(GoodData::Schedule, new_obj_json, client: c, project: p)
      end
    end

    # Initializes object from raw json
    #
    # @param json [Object] Raw JSON
    # @return [GoodData::Schedule] New GoodData::Schedule instance
    def initialize(json)
      super
      @json = json
    end

    # Deletes schedule
    def delete
      client.delete uri
    end

    # Is schedule enabled?
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

    # enables
    #
    # @return [GoodData::Schedule]
    def enable
      @json['schedule']['state'] = 'ENABLED'
      @dirty = true
      self
    end

    # Is schedule enabled?
    #
    # @return [GoodData::Schedule]
    def disable
      @json['schedule']['state'] = 'DISABLED'
      @dirty = true
      self
    end

    # Executes schedule
    #
    # @param [Hash] opts execution options.
    # @option opts [Boolean] :wait Wait for execution result
    # @return [Object] Raw Response
    def execute(opts = { :wait => true })
      data = {
        :execution => {}
      }
      res = client.post(execution_url, data)
      execution = client.create(GoodData::Execution, res, client: client, project: project)

      return execution unless opts[:wait]
      execution.wait_for_result
    end

    # Returns execution URL
    #
    # @return [String] Executions URL
    def execution_url
      @json['schedule']['links']['executions']
    end

    # Returns execution state
    #
    # @return [String] Execution state
    def state
      @json['schedule']['state']
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

    # Returns list of executions
    #
    # @return [Array] Raw Executions JSON
    def executions
      if @json # rubocop:disable Style/GuardClause
        url = @json['schedule']['links']['executions']
        res = client.get url
        res['executions']['items']
      end
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
    def params=(new_param)
      @json['schedule']['params'].merge!(new_param)
      @dirty = true
    end

    # Returns hidden_params as Hash
    #
    # @return [Hash] Hidden Parameters
    def hidden_params
      @json['schedule']['hiddenParams'] || {}
    end

    # Assigns hidden parameters
    #
    # @param new_hidden_param [String] Hidden parameters to be set
    def hidden_params=(new_hidden_param)
      @json['schedule']['hiddenParams'] = hidden_params.merge(new_hidden_param)
      @dirty = true
    end

    # Saves object if dirty
    #
    # @return [Boolean] True if saved
    def save
      if @dirty
        update_json = {
          'schedule' => {
            'type' => @json['schedule']['type'],
            'state' => @json['schedule']['state'],
            'timezone' => @json['schedule']['timezone'],
            'cron' => @json['schedule']['cron'],
            'params' => @json['schedule']['params'],
            'hiddenParams' => @json['schedule']['hiddenParams'],
            'reschedule' => @json['schedule']['reschedule'] || 0
          }
        }
        res = client.put(uri, update_json)
        @json = res
        @dirty = false
        return true
      end
      false
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
  end
end
