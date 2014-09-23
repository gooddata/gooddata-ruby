# encoding: UTF-8

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class Report < GoodData::MdObject
    root_key :report

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('reports', Report, options)
      end

      def create(options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?

        title = options[:title]
        fail 'Report needs a title specified' unless title
        summary = options[:summary] || ''
        rd = options[:rd] || ReportDefinition.create(options)
        rd.save

        report = {
          'report' => {
            'content' => {
              'domains' => [],
              'definitions' => [rd.uri]
            },
            'meta' => {
              'tags' => '',
              'deprecated' => '0',
              'summary' => summary,
              'title' => title
            }
          }
        }
        # TODO: write test for report definitions with explicit identifiers
        report['report']['meta']['identifier'] = options[:identifier] if options[:identifier]
        client.create(Report, report, :project => project)
      end
    end

    # Add a report definition to a report. This will show on a UI as a new version.
    #
    # @param report_definition [GoodData::ReportDefinition | String] Report definition to add. Either it can be a URI of a report definition or an actual report definition object.
    # @return [GoodData::Report] Return self
    def add_definition(report_definition)
      rep_def = project.report_definitions(report_definition)
      content['definitions'] = definition_uris << rep_def.uri
      self
    end

    def results
      content['results']
    end

    def definitions
      content['definitions'].pmap { |uri| project.report_definitions(uri) }
    end

    def definition_uris
      content['definitions']
    end

    def latest_report_definition_uri
      definition_uris.last
    end

    def latest_report_definition
      project.report_definitions(latest_report_definition_uri)
    end

    def remove_definition(definition)
      def_uri = is_a?(GoodData::ReportDefinition) ? definition.uri : definition
      content['definitions'] = definition_uris.reject { |x| x == def_uri }
      self
    end

    # TODO: Cover with test. You would probably need something that will be able to create a report easily from a definition
    def remove_definition_but_latest
      to_remove = definition_uris - [latest_report_definition_uri]
      to_remove.each do |uri|
        remove_definition(uri)
      end
      self
    end

    def purge_report_of_unused_definitions!
      full_list = definition_uris
      remove_definition_but_latest
      purged_list = definition_uris
      to_remove = full_list - purged_list
      save
      to_remove.each { |uri| client.delete(uri) }
      self
    end

    def execute
      fail 'You have to save the report before executing. If you do not want to do that please use GoodData::ReportDefinition' unless saved?
      result = client.post '/gdc/xtab2/executor3', 'report_req' => { 'report' => uri }
      data_result_uri = result['execResult']['dataResult']

      result = client.poll_on_response(data_result_uri) do |body|
        body && body['taskState'] && body['taskState']['status'] == 'WAIT'
      end

      if result.empty?
        client.create(EmptyResult, result)
      else
        client.create(ReportDataResult, result)
      end
    end

    def exportable?
      true
    end

    def export(format)
      result = GoodData.post('/gdc/xtab2/executor3', 'report_req' => { 'report' => uri })
      result1 = GoodData.post('/gdc/exporter/executor', :result_req => { :format => format, :result => result })
      GoodData.poll_on_code(result1['uri'], process: false)
    end

    def replace(what, for_what)
      new_defs = definitions.map do |rep_def|
        rep_def.replace(what, for_what)
      end
      new_defs.pmap(&:save)
    end
  end
end
