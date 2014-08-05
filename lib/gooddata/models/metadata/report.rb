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
      def all(options = {})
        query('reports', Report, options)
      end

      def create(options = {})
        title = options[:title]
        summary = options[:summary] || ''
        rd = options[:rd] || ReportDefinition.create(:top => options[:top], :left => options[:left])
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
        Report.new report
      end
    end

    def results
      content['results']
    end

    def definitions
      content['definitions']
    end

    def latest_report_definition_uri
      definitions.last
    end

    def latest_report_definition
      GoodData::MdObject[latest_report_definition_uri]
    end

    def remove_definition(definition)
      def_uri = is_a?(GoodData::ReportDefinition) ? definition.uri : definition
      content['definitions'] = definitions.reject { |x| x == def_uri }
      self
    end

    # TODO: Cover with test. You would probably need something that will be able to create a report easily from a definition
    def remove_definition_but_latest
      to_remove = definitions - [latest_report_definition_uri]
      to_remove.each do |uri|
        remove_definition(uri)
      end
      self
    end

    def purge_report_of_unused_definitions!
      full_list = definitions
      remove_definition_but_latest
      purged_list = definitions
      to_remove = full_list - purged_list
      save
      to_remove.each { |uri| GoodData.delete(uri) }
      self
    end

    def execute
      fail 'You have to save the report before executing. If you do not want to do that please use GoodData::ReportDefinition' unless saved?
      result = GoodData.post '/gdc/xtab2/executor3', 'report_req' => { 'report' => uri }
      data_result_uri = result['execResult']['dataResult']
      result = GoodData.get data_result_uri
      while result['taskState'] && result['taskState']['status'] == 'WAIT'
        sleep 10
        result = GoodData.get data_result_uri
      end
      ReportDataResult.new(GoodData.get data_result_uri)
    end

    def exportable?
      true
    end

    def export(format)
      result = GoodData.post('/gdc/xtab2/executor3', 'report_req' => { 'report' => uri })
      result1 = GoodData.post('/gdc/exporter/executor', :result_req => { :format => format, :result => result })
      GoodData.poll_on_code(result1['uri'], process: false)
    end
  end
end
