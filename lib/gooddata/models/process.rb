# encoding: UTF-8

require 'pry'

require_relative '../rest/resource'

module GoodData
  class Process < GoodData::Rest::Object
    attr_reader :data

    alias_method :raw_data, :data
    alias_method :json, :data
    alias_method :to_hash, :data

    class << self
      def [](id, options = {})
        project = options[:project]
        c = client(options)

        if id == :all && project
          uri = "/gdc/projects/#{project.pid}/dataload/processes"
          data = c.get(uri)
          data['processes']['items'].map do |process_data|
            c.create(Process, process_data, project: project)
          end
        elsif id == :all
          uri = "/gdc/account/profile/#{c.user.obj_id}/dataload/processes"
          data = c.get(uri)
          pids = data['processes']['items'].map { |process_data| process_data['process']['links']['self'].match(%r{/gdc/projects/(\w*)/})[1] }.uniq
          projects_lookup = pids.pmap { |pid| c.projects(pid) }.reduce({}) do |a, e|
            a[e.pid] = e
            a
          end

          data['processes']['items'].map do |process_data|
            pid = process_data['process']['links']['self'].match(%r{/gdc/projects/(\w*)/})[1]
            c.create(Process, process_data, project: projects_lookup[pid])
          end
        else
          uri = "/gdc/projects/#{project.pid}/dataload/processes/#{id}"
          c.create(Process, c.get(uri), project: project)
        end
      end

      def all
        Process[:all]
      end

      # TODO: Check the params.
      def with_deploy(dir, options = {}, &block)
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        GoodData.with_project(project) do
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

      def upload_package(path, files_to_exclude, opts = { :client => GoodData.connection })
        client = opts[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = opts[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, opts]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        if !path.directory? && (path.extname == '.grf' || path.extname == '.rb')
          puts 'Creating package for upload'
          Tempfile.open('deploy-graph-archive') do |temp|
            Zip::OutputStream.open(temp.path) do |zio|
              FileUtils.cd(path.parent) do
                files_to_pack = [path.basename]
                files_to_pack.each do |item|
                  puts "including #{item}"
                  unless File.directory?(item)
                    zio.put_next_entry(item)
                    zio.print IO.read(item)
                  end
                end
              end
            end

            client.upload_to_user_webdav(temp.path, opts)
            temp.path
          end
        elsif !path.directory?
          client.upload_to_user_webdav(path, opts)
          path
        else
          Tempfile.open('deploy-graph-archive') do |temp|
            Zip::OutputStream.open(temp.path) do |zio|
              FileUtils.cd(path) do

                files_to_pack = Dir.glob('./**/*').reject { |f| files_to_exclude.include?(Pathname(path) + f) }
                files_to_pack.each do |item|
                  puts "including #{item}"
                  unless File.directory?(item)
                    zio.put_next_entry(item)
                    zio.print IO.read(item)
                  end
                end
              end
            end

            client.upload_to_user_webdav(temp.path, opts)
            temp.path
          end
        end
      end

      # Deploy a new process or redeploy existing one.
      #
      # @param path [String] Path to ZIP archive or to a directory containing files that should be ZIPed
      # @option options [String] :files_to_exclude
      # @option options [String] :type ('GRAPH') Type of process - GRAPH or RUBY
      # @option options [String] :name Readable name of the process
      # @option options [String] :process_id ID of a process to be redeployed (do not set if you want to create a new process)
      # @option options [Boolean] :verbose (false) Switch on verbose mode for detailed logging
      def deploy(path, options = {})
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'No :project specified' if project.nil?

        path = Pathname(path) || fail('Path is not specified')
        files_to_exclude = options[:files_to_exclude].nil? ? [] : options[:files_to_exclude].map { |pname| Pathname(pname) }
        process_id = options[:process_id]

        type = options[:type] || 'GRAPH'
        deploy_name = options[:name]
        fail ArgumentError, 'options[:name] can not be nil or empty!' if deploy_name.nil? || deploy_name.empty?

        verbose = options[:verbose] || false
        puts HighLine.color("Deploying #{path}", HighLine::BOLD) if verbose

        deployed_path = Process.upload_package(path, files_to_exclude, :client => client, :project => project)
        data = {
          :process => {
            :name => deploy_name,
            :path => "/uploads/#{File.basename(deployed_path)}",
            :type => type
          }
        }

        res = if process_id.nil?
                client.post("/gdc/projects/#{project.pid}/dataload/processes", data)
              else
                client.put("/gdc/projects/#{project.pid}/dataload/processes/#{process_id}", data)
              end

        process = client.create(Process, res, project: p)
        puts HighLine.color("Deploy DONE #{path}", HighLine::GREEN) if verbose
        process
      end
    end

    def initialize(data)
      @data = data
    end

    def delete
      client.delete(uri)
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
      data['process']
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
      project.schedules.select { |schedule| schedule.process_id == obj_id }
    end

    def create_schedule(cron, executable, options = {})
      project.create_schedule(process_id, cron, executable, options.merge(client: client, project: project))
    end

    def execute(executable, options = {})
      params = options[:params] || {}
      hidden_params = options[:hidden_params] || {}
      result = client.post(executions_link,
                           :execution => {
                             :graph => executable.to_s,
                             :params => params,
                             :hiddenParams => hidden_params
                           })
      begin
        client.poll_on_code(result['executionTask']['links']['poll'])
      rescue RestClient::RequestFailed => e
        raise(e)
      ensure
        result = client.get(result['executionTask']['links']['detail'])
        if result['executionDetail']['status'] == 'ERROR'
          fail "Runing process failed. You can look at a log here #{result["executionDetail"]["logFileName"]}"
        end
      end
      result
    end
  end
end
