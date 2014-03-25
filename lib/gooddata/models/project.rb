# encoding: UTF-8

require 'zip'
require 'fileutils'

module GoodData
  class NoProjectError < RuntimeError;
  end

  class Project
    USERSPROJECTS_PATH = '/gdc/account/profile/%s/projects'
    PROJECTS_PATH = '/gdc/projects'
    PROJECT_PATH = '/gdc/projects/%s'
    SLIS_PATH = '/ldm/singleloadinterface'

    attr_accessor :connection

    class << self
      # Returns an array of all projects accessible by
      # current user
      def all
        json = GoodData.get GoodData.profile.projects
        json['projects'].map do |project|
          Project.new project
        end
      end

      # Returns a Project object identified by given string
      # The following identifiers are accepted
      #  - /gdc/md/<id>
      #  - /gdc/projects/<id>
      #  - <id>
      #
      def [](id)
        return id if id.respond_to?(:is_project?) && id.is_project?
        if id == :all
          Project.all
        else
          if id.to_s !~ /^(\/gdc\/(projects|md)\/)?[a-zA-Z\d]+$/
            raise ArgumentError.new('wrong type of argument. Should be either project ID or path')
          end

          id = id.match(/[a-zA-Z\d]+$/)[0] if id =~ /\//

          response = GoodData.get PROJECT_PATH % id
          Project.new response
        end
      end

      # Create a project from a given attributes
      # Expected keys:
      # - :title (mandatory)
      # - :summary
      # - :template (default /projects/blank)
      #
      def create(attributes, &block)
        GoodData.logger.info "Creating project #{attributes[:title]}"

        auth_token = attributes[:auth_token] || GoodData.connection.auth_token

        json = {:project =>
                  {
                    'meta' => {
                      'title' => attributes[:title],
                      'summary' => attributes[:summary] || 'No summary'
                    },
                    'content' => {
                      'guidedNavigation' => 1,
                      'authorizationToken' => auth_token,
                      'driver' => 'Pg'
                    }
                  }
        }
        json['meta']['projectTemplate'] = attributes[:template] if attributes[:template] && !attributes[:template].empty?
        project = Project.new json
        project.save
        if block
          GoodData::with_project(project) do |p|
            block.call(p)
          end
        end
        project
      end
    end

    def initialize(json)
      @json = json
    end

    def save
      response = GoodData.post PROJECTS_PATH, raw_data
      if uri == nil
        response = GoodData.get response['uri']
        @json = response
      end
    end

    def delete
      raise "Project '#{title}' with id #{uri} is already deleted" if state == :deleted
      GoodData.delete(uri)
    end

    def uri
      data['links']['self'] if data && data['links'] && data['links']['self']
    end

    def browser_uri(options={})
      ui = options[:ui]
      if ui
        GoodData.connection.url + '#s=' + uri
      else
        GoodData.connection.url + uri
      end
    end

    def obj_id
      uri.split('/').last
    end

    alias :pid :obj_id


    def title
      data['meta']['title'] if data['meta']
    end

    def state
      data['content']['state'].downcase.to_sym if data['content'] && data['content']['state']
    end

    def md
      @md ||= Links.new GoodData.get(data['links']['metadata'])
    end

    # Creates a data set within the project
    #
    # == Usage
    # p.add_dataset 'Test', [ { 'name' => 'a1', 'type' => 'ATTRIBUTE' ... } ... ]
    # p.add_dataset 'title' => 'Test', 'columns' => [ { 'name' => 'a1', 'type' => 'ATTRIBUTE' ... } ... ]
    #
    def add_dataset(schema_def, columns = nil, &block)
      schema = if block
                 builder = block.call(Model::SchemaBuilder.new(schema_def))
                 builder.to_schema
               else
                 sch = {:title => schema_def, :columns => columns} if columns
                 sch = Model::Schema.new schema_def if schema_def.is_a? Hash
                 sch = schema_def if schema_def.is_a?(Model::Schema)
                 raise ArgumentError.new('Required either schema object or title plus columns array') unless schema_def.is_a? Model::Schema
                 sch
               end
      Model.add_schema(schema, self)
    end

    def add_metric(options={})
      expression = options[:expression] || fail('Metric has to have its expression defined')
      m1 = GoodData::Metric.create(options)
      m1.save
    end

    def add_report(options={})
      rep = GoodData::Report.create(options)
      rep.save
    end

    def add_dashboard(options={})
      dash = GoodData::Dashboard.create(options)
      dash.save
    end

    def add_user(email_address, domain)
      raise 'Not implemented'
    end

    def upload(file, schema, mode = 'FULL')
      schema.upload file, self, mode
    end

    def slis
      link = "#{data['links']['metadata']}#{SLIS_PATH}"

      # TODO: Review what to do with passed extra argument
      Metadata.new GoodData.get(link)
    end

    def datasets
      datasets_uri = "#{md['data']}/sets"
      response = GoodData.get datasets_uri
      response['dataSetsInfo']['sets'].map do |ds|
        DataSet[ds['meta']['uri']]
      end
    end

    def raw_data
      @json
    end

    def data
      raw_data['project']
    end

    def links
      data['links']
    end

    def to_json
      raw_data.to_json
    end

    def is_project?
      true
    end
  end
end
