# encoding: UTF-8

require 'pry'

module GoodData
  class Process
    attr_reader :data

    class << self
      def [](id)
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
              self_link = res && res['process']['links']['self']
              GoodData.delete(self_link)
            end
          else
            GoodData::Process.deploy(dir, options.merge(:files_to_exclude => params))
          end
        end
      end

      def upload_package(dir, files_to_exclude)
        Tempfile.open('deploy-graph-archive') do |temp|
          Zip::OutputStream.open(temp.path) do |zio|
            FileUtils.cd(dir) do

              files_to_pack = Dir.glob('./**/*').reject { |f| files_to_exclude.include?(Pathname(dir) + f) }
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
          temp
        end
      end

      def deploy(dir, options = {})
        dir = Pathname(dir) || fail('Directory is not specified')
        fail "\"#{dir}\" is not a directory" unless dir.directory?
        files_to_exclude = options[:files_to_exclude].map { |p| Pathname(p) }
        process_id = options[:process_id]

        type = options[:type] || 'GRAPH'
        deploy_name = options[:name]
        verbose = options[:verbose] || false
        puts HighLine.color("Deploying #{dir}", HighLine::BOLD) if verbose
        deployed_path = Process.upload_package(dir, files_to_exclude)
        data = {
          :process => {
            :name => deploy_name,
            :path => "/uploads/#{File.basename(deployed_path.path)}",
            :type => type
          }
        }
        res = if process_id.nil?
                GoodData.post("/gdc/projects/#{GoodData.project.pid}/dataload/processes", data)
              else
                GoodData.put("/gdc/projects/#{GoodData.project.pid}/dataload/processes/#{process_id}", data)
              end
        process = Process.new(res)
        puts HighLine.color("Deploy DONE #{dir}", HighLine::GREEN) if verbose
        process
      end
    end

    def initialize(data)
      @data = data
    end

    def delete
      GoodData.delete(uri)
    end

    def deploy(dir, options = {})
      process = Process.upload(dir, options.merge(:process_id => process_id))
      puts HighLine.color("Deploy DONE #{dir}", HighLine::GREEN) if verbose
      process
    end

    def process
      raw_data['process']
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
