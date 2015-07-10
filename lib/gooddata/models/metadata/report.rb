# encoding: UTF-8

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class Report < GoodData::MdObject
    root_key :report

    include GoodData::Mixin::Lockable

    class << self
      # Method intended to get all objects of that type in a specified project
      #
      # @param options [Hash] the options hash
      # @option options [Boolean] :full if passed true the subclass can decide to pull in full objects. This is desirable from the usability POV but unfortunately has negative impact on performance so it is not the default
      # @return [Array<GoodData::MdObject> | Array<Hash>] Return the appropriate metadata objects or their representation
      def all(options = { :client => GoodData.connection, :project => GoodData.project })
        query('report', Report, options)
      end

      def create(options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = client.projects(p)
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

    # Gets a report definitions (versions) of this report as objects.
    #
    # @return [Array<GoodData::ReportDefinition>] Returns list of report definitions. Oldest comes first
    def definitions
      content['definitions'].pmap { |uri| project.report_definitions(uri) }
    end
    alias_method :report_definitions, :definitions

    # Gets list of uris of report definitions (versions) of this report.
    #
    # @return [Array<String>] Returns list of report definitions' uris. Oldest comes first
    def definition_uris
      content['definitions']
    end

    # Deletes report along with its report definitions.
    #
    # @return [GoodData::Report] Returns self
    def delete
      defs = definitions
      super
      defs.peach(&:delete)
      self
    end

    # Computes the report and returns the result. If it is not computable returns nil.
    #
    # @return [GoodData::DataResult] Returns the result
    def execute(options = {})
      fail 'You have to save the report before executing. If you do not want to do that please use GoodData::ReportDefinition' unless saved?
      result = client.post '/gdc/xtab2/executor3', 'report_req' => { 'report' => uri }
      data_result_uri = result['execResult']['dataResult']

      result = client.poll_on_response(data_result_uri, options) do |body|
        body && body['taskState'] && body['taskState']['status'] == 'WAIT'
      end

      if result.empty?
        client.create(EmptyResult, result)
      else
        client.create(ReportDataResult, result)
      end
    end

    # Returns true if you can export and object
    #
    # @return [Boolean] Returns whether the report is exportable
    def exportable?
      true
    end

    # Returns binary data of the exported report in a given format. The format can be
    # either 'csv', 'xls', 'xlsx' or 'pdf'.
    #
    # @return [String] Returns data
    def export(format, options = {})
      result = client.post('/gdc/xtab2/executor3', 'report_req' => { 'report' => uri })
      result1 = client.post('/gdc/exporter/executor', :result_req => { :format => format, :result => result })
      client.poll_on_code(result1['uri'], options.merge(process: false))
    end

    # Returns the newest (current version) report definition uri
    #
    # @return [String] Returns uri of the newest report defintion
    def latest_report_definition_uri
      definition_uris.last
    end

    # Returns the newest (current version) report definition as an object
    #
    # @return [GoodData::ReportDefinition] Returns the newest report defintion
    def latest_report_definition
      project.report_definitions(latest_report_definition_uri)
    end

    # Returns the newest (current version) report definition uri
    #
    # @return [String] Returns uri of the newest report defintion
    def purge_report_of_unused_definitions!
      full_list = definition_uris
      remove_definition_but_latest
      purged_list = definition_uris
      to_remove = full_list - purged_list
      save
      to_remove.each { |uri| client.delete(uri) }
      self
    end

    # Removes definition from the report. The definition to remove can be passed in any form that is accepted by
    # GoodData::ReportDefintion[]
    #
    # @param definition [String | GoodData::ReportDefinition] Report defintion to remove
    # @return [GoodData::Report] Returns report with removed definition
    def remove_definition(definition)
      a_def = GoodData::ReportDefinition[definition, project: project, client: client]
      def_uri = a_def.uri
      content['definitions'] = definition_uris.reject { |x| x == def_uri }
      self
    end

    # TODO: Cover with test. You would probably need something that will be able to create a report easily from a definition
    # Removes all definitions but the latest from the report. This is useful for cleaning up before you create
    # a template out of a project.
    #
    # @return [GoodData::Report] Returns report with removed definitions
    def remove_definition_but_latest
      to_remove = definition_uris - [latest_report_definition_uri]
      to_remove.each do |uri|
        remove_definition(uri)
      end
      self
    end

    # Replaces all occurences of something with something else. This is just a convenience method. The
    # real work is done under the hood in report definition. This is just deferring to those
    #
    # @param what [Object] What you would like to have changed
    # @param for_what [Object] What you would like to have changed this for
    # @return [GoodData::Report] Returns report with removed definition
    def replace(what, for_what)
      new_defs = definitions.map do |rep_def|
        rep_def.replace(what, for_what)
      end
      new_defs.pmap(&:save)
      self
    end
  end
end
