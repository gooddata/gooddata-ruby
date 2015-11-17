# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative '../metadata'
require_relative 'metadata'

module GoodData
  class Report < GoodData::MdObject
    include Mixin::Lockable

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
        client, project = GoodData.get_client_and_project(options)

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

      def data_result(result, options = {})
        client = options[:client]
        data_result_uri = result['execResult']['dataResult']
        begin
          result = client.poll_on_response(data_result_uri, options) do |body|
            body && body['taskState'] && body['taskState']['status'] == 'WAIT'
          end
        rescue RestClient::BadRequest => e
          resp = JSON.parse(e.response)
          if GoodData::Helpers.get_path(resp, %w(error component)) == 'MD::DataResult'
            raise GoodData::UncomputableReport
          else
            raise e
          end
        end

        if result.empty?
          ReportDataResult.new(data: [], top: 0, left: 0)
        else
          ReportDataResult.from_xtab(result)
        end
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

    # Add a report definition to a report. This will show on a UI as a new version.
    #
    # @param report_definition [GoodData::ReportDefinition | String] Report definition to add. Either it can be a URI of a report definition or an actual report definition object.
    # @return [GoodData::Report] Return self
    def add_definition!(report_definition)
      res = add_definition(report_definition)
      res.save
    end

    # Returns the newest (current version) report definition as an object
    #
    # @return [GoodData::ReportDefinition] Returns the newest report defintion
    def definition
      project.report_definitions(latest_report_definition_uri)
    end

    alias_method :latest_report_definition, :definition

    # Returns the newest (current version) report definition uri
    #
    # @return [String] Returns uri of the newest report defintion
    def definition_uri
      definition_uris.last
    end

    alias_method :latest_report_definition_uri, :definition_uri

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
      GoodData::Report.data_result(result, options.merge(client: client))
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

    # Method used for replacing values in their state according to mapping. Can be used to replace any values but it is typically used to replace the URIs. Returns a new object of the same type.
    #
    # @param [Array<Array>]Mapping specifying what should be exchanged for what. As mapping should be used output of GoodData::Helpers.prepare_mapping.
    # @return [GoodData::Report]
    def replace(mapping)
      new_defs = definitions.map do |rep_def|
        rep_def.replace(mapping)
      end
      new_defs.pmap(&:save)
      self
    end

    ## Update report definition and reflect the change in report
    #
    # @param [Hash] opts Options
    # @option opts [Boolean] :new_definition (true) If true then new definition will be created
    # @return [GoodData::ReportDefinition] Updated and saved report definition
    def update_definition(opts = { :new_definition => true }, &block)
      # TODO: Cache the latest report definition somehow
      repdef = definition.dup

      block.call(repdef, self) if block_given?

      if opts[:new_definition]
        new_def = GoodData::ReportDefinition.create(:client => client, :project => project)

        rd = repdef.json['reportDefinition']
        rd.delete('links')
        %w(author uri created identifier updated contributor).each { |k| rd['meta'].delete(k) }
        new_def.json['reportDefinition'] = rd
        new_def.save

        add_definition!(new_def)
        return new_def
      else
        repdef.save
      end

      repdef
    end
  end
end
