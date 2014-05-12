# encoding: UTF-8

module GoodData
  class Schedule
    attr_reader :dirty

    class << self
      # Looks for schedule
      # @param id [String] URL, ID of schedule or :all
      # @return [GoodData::Schedule|Array<GoodData::Schedule>] List of schedules
      def [](id, options = {})
        if id == :all
          GoodData::Schedule.all
        else
          if id =~ %r{\/gdc\/projects\/[a-zA-Z\d]+\/schedules\/?[a-zA-Z\d]*}
            url = id
            tmp = GoodData.get url
            return GoodData::Schedule.new(tmp)
          end

          tmp = GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules/#{id}"
          GoodData::Schedule.new(tmp)
        end
      end

      # Returns list of all schedules for active project
      # @return [Array<GoodData::Schedule>] List of schedules
      def all
        res = []
        tmp = GoodData.get "/gdc/projects/#{GoodData.project.pid}/schedules"
        tmp['schedules']['items'].each do |schedule|
          res << GoodData::Schedule.new(schedule)
        end
        res
      end

      # Creates new schedules from parameters passed
      #
      # @param process_id [String] Process ID
      # @param cron [String] Cron Settings
      # @param executable [String] Execution executable
      # @param options [Hash] Optional options
      # @return [GoodData::Schedule] New GoodData::Schedule instance
      def create(process_id, cron, executable, options = {})
        default_opts = {
          :type => 'MSETL',
          :timezone => 'UTC',
          :cron => cron,
          :params => {
            :process_id => process_id,
            :executable => executable
          },
          :hidden_params => {}
        }

        inject_schema = {
          :hidden_params => 'hiddenParams'
        }

        inject_params = {
          :process_id => 'PROCESS_ID',
          :executable => 'EXECUTABLE'
        }

        default_params = default_opts[:params].reduce({}) do |new_hash, (k, v)|
          key = inject_params[k] || k
          new_hash[key] = v
          new_hash
        end

        default = default_opts.reduce({}) do |new_hash, (k, v)|
          key = inject_schema[k] || k
          new_hash[key] = v
          new_hash
        end

        default[:params] = default_params

        json = {
          'schedule' => default.merge(options)
        }

        tmp = json['schedule'][:params]['PROCESS_ID']
        fail 'Process ID has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:params]['EXECUTABLE']
        fail 'Executable has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:cron]
        fail 'Cron schedule has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:timezone]
        fail 'A timezone has to be provided' if tmp.nil? || tmp.empty?

        tmp = json['schedule'][:type]
        fail 'Schedule type has to be provided' if tmp.nil? || tmp.empty?

        url = "/gdc/projects/#{GoodData.project.pid}/schedules"
        res = GoodData.post url, json

        fail 'Unable to create new schedule' if res.nil?

        new_obj_json = GoodData.get res['schedule']['links']['self']
        GoodData::Schedule.new(new_obj_json)
      end
    end

    # Initializes object from raw json
    #
    # @param json [Object] Raw JSON
    # @return [GoodData::Schedule] New GoodData::Schedule instance
    def initialize(json)
      @json = json
    end

    # Deletes schedule
    def delete
      GoodData.delete uri
    end

    # Executes schedule
    #
    # @return [Object] Raw Response
    def execute
      data = {
        :execution => {}
      }
      GoodData.post execution_url, data
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
      if @json
        url = @json['schedule']['links']['executions']
        res = GoodData.get url
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
            'timezone' => @json['schedule']['timezone'],
            'cron' => @json['schedule']['cron'],
            'params' => @json['schedule']['params'],
            'hiddenParams' => @json['schedule']['hiddenParams']
          }
        }
        res = GoodData.put uri, update_json

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
  end
end
