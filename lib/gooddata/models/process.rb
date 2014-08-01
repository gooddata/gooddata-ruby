# encoding: UTF-8

require 'pry'

module GoodData
  class Process
    attr_reader :data

    class << self
      def [](id, options = {})
        if id == :all
          uri = "/gdc/projects/#{GoodData.project.pid}/dataload/processes"
          data = GoodData.get(uri)
          data['processes']['items'].map do |process_data|
            Process.new(process_data)
          end
        else
          uri = "/gdc/projects/#{GoodData.project.pid}/dataload/processes/#{id}"
          new(GoodData.get(uri))
        end
      end

      def all
        Process[:all]
      end

      # TODO: Check the params.
      def with_deploy(dir, options = {}, &block)
        # verbose = options[:verbose] || false
        GoodData.with_project(options[:project_id]) do |project|
          params = options[:params].nil? ? [] : [options[:params]]
          if block
            begin
              res = GoodData::Process.deploy(dir, options.merge(:files_to_exclude => params))
              block.call(res)
            ensure
              res.delete if res
            end
          else
            GoodData::Process.deploy(dir, options.merge(:files_to_exclude => params))
          end
        end
      end

      def upload_package(path, files_to_exclude)
        if !path.directory?
          GoodData.upload_to_user_webdav(path)
          path
        else
          Tempfile.open('deploy-graph-archive') do |temp|
            Zip::OutputStream.open(temp.path) do |zio|
              FileUtils.cd(path) do

                files_to_pack = Dir.glob('./**/*').reject { |f| files_to_exclude.include?(Pathname(path) + f) }
                files_to_pack.each do |item|
                  # puts "including #{item}" if verbose
                  unless File.directory?(item)
                    zio.put_next_entry(item)
                    zio.print IO.read(item)
                  end
                end
              end
            end
            GoodData.upload_to_user_webdav(temp.path)
            temp.path
          end
        end
      end

      # Deploy a new process or redeploy existing one.
      #
      # @param path [String] Path to ZIP archive or to a directory containing files that should be ZIPed
      # @option options [String] :files_to_exclude
      # @option options [String] :process_id ('nobody') From address
      # @option options [String] :type ('GRAPH') Type of process - GRAPH or RUBY
      # @option options [String] :name Readable name of the process
      # @option options [String] :process_id ID of a process to be redeployed (do not set if you want to create a new process)
      # @option options [Boolean] :verbose (false) Switch on verbose mode for detailed logging
      def deploy(path, options = {})
        path = Pathname(path) || fail('Path is not specified')
        files_to_exclude = options[:files_to_exclude].nil? ? [] : options[:files_to_exclude].map { |p| Pathname(p) }
        process_id = options[:process_id]

        type = options[:type] || 'GRAPH'
        deploy_name = options[:name]
        fail ArgumentError, 'options[:deploy_name] can not be nil or empty!' if deploy_name.nil? || deploy_name.empty?

        verbose = options[:verbose] || false
        puts HighLine.color("Deploying #{path}", HighLine::BOLD) if verbose
        deployed_path = Process.upload_package(path, files_to_exclude)
        data = {
          :process => {
            :name => deploy_name,
            :path => "/uploads/#{File.basename(deployed_path)}",
            :type => type
          }
        }

        res = if process_id.nil?
                GoodData.post("/gdc/projects/#{GoodData.project.pid}/dataload/processes", data)
              else
                GoodData.put("/gdc/projects/#{GoodData.project.pid}/dataload/processes/#{process_id}", data)
              end

        process = Process.new(res)
        puts HighLine.color("Deploy DONE #{path}", HighLine::GREEN) if verbose
        process
      end
    end

    def initialize(data)
      @data = data
    end

    def delete
      GoodData.delete(uri)
    end

    # Redeploy existing process.
    #
    # @param path [String] Path to ZIP archive or to a directory containing files that should be ZIPed
    # @option options [String] :files_to_exclude
    # @option options [String] :process_id ('nobody') From address
    # @option options [String] :type ('GRAPH') Type of process - GRAPH or RUBY
    # @option options [String] :name Readable name of the process
    # @option options [Boolean] :verbose (false) Switch on verbose mode for detailed logging
    def deploy(path, options = {})
      Process.deploy(path, options.merge(:process_id => process_id))
    end

    def process
      json['process']
    end

    def name
      process['name']
    end

    def type
      process['type'].downcase.to_sym
    end

    def links
      process['links']
    end

    def link
      links['self']
    end
    alias_method :uri, :link

    def obj_id
      uri.split('/').last
    end

    alias_method :process_id, :obj_id

    def executions_link
      links['executions']
    end

    def graphs
      process['graphs']
    end

    def executables
      process['executables']
    end

    def schedules
      res = []

      scheds = GoodData::Schedule[:all]
      scheds['schedules']['items'].each do |item|
        if item['schedule']['params']['PROCESS_ID'] == obj_id
          res << GoodData::Schedule.new(item)
        end
      end

      res
    end

    alias_method :raw_data, :data

    def execute(executable, options = {})
      params = options[:params] || {}
      hidden_params = options[:hidden_params] || {}
      result = GoodData.post(executions_link,
                             :execution => {
                               :graph => executable.to_s,
                               :params => params,
                               :hiddenParams => hidden_params
                             })
      begin
        GoodData.poll(result, 'executionTask')
      rescue RestClient::RequestFailed => e
        raise(e)
      ensure
        result = GoodData.get(result['executionTask']['links']['detail'])
        if result['executionDetail']['status'] == 'ERROR'
          fail "Runing process failed. You can look at a log here #{result["executionDetail"]["logFileName"]}"
        end
      end
      result
    end
  end
end
