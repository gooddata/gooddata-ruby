# encoding: UTF-8

require_relative '../core/rest'

require_relative 'metadata/metadata'

require_relative 'links'
require_relative 'module_constants'
require_relative 'user_filters/user_filters'
require_relative 'blueprint/blueprint'

require 'fileutils'
require 'multi_json'
require 'open-uri'
require 'zip'

##
# Module containing classes that counter-part GoodData server-side meta-data
# elements, including the server-side data model.
#
module GoodData
  module Model
    # See https://confluence.intgdc.com/display/plat/Catalog+of+Attribute+Types
    GD_TYPES = [
      # Common Types
      'GDC.link',
      'GDC.text',
      'GDC.time',

      # Common Date Attribute Types
      'GDC.time.year',
      'GDC.time.quarter',
      'GDC.time.month',
      'GDC.time.week',
      'GDC.time.date',

      # Specific Date Attribute Types
      'GDC.time.day_in_euweek',
      'GDC.time.day_in_week',
      'GDC.time.day_in_month',
      'GDC.time.day_in_quarter',
      'GDC.time.day_in_year',
      'GDC.time.euweek_in_quarter',
      'GDC.time.week_in_quarter',
      'GDC.time.euweek_in_year',
      'GDC.time.week_in_year',
      'GDC.time.month_in_quarter',
      'GDC.time.month_in_year',
      'GDC.time.quarter_in_year',

      # Legacy Date Attribute Types - Possibly Obsolete
      'GDC.time.dayOfWeek',
      'GDC.time.dayOfMonth',
      'GDC.time.dayOfQuarter',
      'GDC.time.dayOfYear',
      'GDC.time.weekOfYear',
      'GDC.time.monthOfYear',
      'GDC.time.quarterOfYear',

      # Types for Geo
      'GDC.geo.pin',                 # Geo pushpin
      'GDC.geo.ausstates.name',      # Australia States (Name)
      'GDC.geo.ausstates.code',      # Australia States (ISO code)
      'GDC.geo.usstates.name',       # US States (Name)
      'GDC.geo.usstates.geo_id',     # US States (US Census ID)
      'GDC.geo.usstates.code',       # US States (2-letter code)
      'GDC.geo.uscounties.geo_id',   # US Counties (US Census ID)
      'GDC.geo.worldcountries.name', # World countries (Name)
      'GDC.geo.worldcountries.iso2', # World countries (ISO a2)
      'GDC.geo.worldcountries.iso3', # World countries (ISO a3)
      'GDC.geo.czdistricts.name',    #	Czech Districts (Name)
      'GDC.geo.czdistricts.name_no_diacritics', # Czech Districts
      'GDC.geo.czdistricts.nuts4',   # Czech Districts (NUTS 4)
      'GDC.geo.czdistricts.knok',    # Czech Districts (KNOK)

      # Day Display Forms
      'GDC.time.day',              # yyyy-MM-dd
      'GDC.time.day_us',           # MM/dd/yyyy
      'GDC.time.day_eu',           # dd/MM/yyyy
      'GDC.time.day_iso',          # dd-MM-yyyy
      'GDC.time.day_us_long',      # EEE, MMM d, yyyy
      'GDC.time.day_us_noleading', # M/d/yy
    ]

    GD_DATA_TYPES = ['BIGINT', 'DOUBLE', 'INTEGER', 'INT', /^VARCHAR\(\d{1,3}\)$/i, /^DECIMAL\(\d{1,3},\s*\d{1,3}\)$/i]

    DEFAULT_FACT_DATATYPE = 'DECIMAL(12,2)'
    DEFAULT_ATTRIBUTE_DATATYPE = 'VARCHAR(128)'

    DEFAULT_TYPE = 'GDC.text'

    DEFAULT_DATE_FORMAT = 'MM/dd/yyyy'

    class << self
      def title(item)
        item[:title] || GoodData::Helpers.titleize(item[:id])
      end

      def column_name(item)
        item[:column_name] || item[:id]
      end

      def description(item)
        item[:description]
      end

      def check_gd_type(value)
        GD_TYPES.any? { |v| v == value }
      end

      def check_gd_data_type(value)
        GD_DATA_TYPES.any? do |v|
          case v
          when Regexp
            v =~ value
          when String
            v == (value && value.upcase)
          else
            fail 'Unkown predicate'
          end
        end
      end

      def normalize_gd_data_type(type)
        if type && type.upcase == 'INTEGER'
          'INT'
        else
          type
        end
      end

      # Load given file into a data set described by the given schema
      def upload_data(path, project_blueprint, dataset, options = { :client => GoodData.connection, :project => GoodData.project })
        client = options[:client]
        fail ArgumentError, 'No :client specified' if client.nil?

        p = options[:project]
        fail ArgumentError, 'No :project specified' if p.nil?

        project = GoodData::Project[p, options]
        fail ArgumentError, 'Wrong :project specified' if project.nil?
        # path = if path =~ URI.regexp
        #   Tempfile.open('remote_file') do |temp|
        #     temp << open(path).read
        #     temp.flush
        #     # GoodData::Model.upload_data(path, to_manifest(mode))
        #   end
        #
        # else
        #   # GoodData::Model.upload_data(path, to_manifest(mode))
        #   # upload_data(path, mode)
        # end

        mode = options[:mode] || 'FULL'
        manifest = GoodData::Model::ToManifest.dataset_to_manifest(project_blueprint, dataset, mode)
        project = options[:project] || GoodData.project

        path = path.path if path.respond_to? :path
        inline_data = path.is_a?(String) ? false : true
        csv_header = nil

        # create a temporary zip file
        dir = Dir.mktmpdir
        begin
          Zip::File.open("#{dir}/upload.zip", Zip::File::CREATE) do |zip|
            # TODO: make sure schema columns match CSV column names
            zip.get_output_stream('upload_info.json') { |f| f.puts JSON.pretty_generate(manifest) }
            if inline_data
              csv_header = path.first
              zip.get_output_stream('data.csv') do |f|
                path.each do |row|
                  f.puts row.to_csv
                end
              end
            else
              csv_header = File.open(path, &:gets).split(',')
              zip.add('data.csv', path)
            end
          end

          # upload it
          client.upload_to_user_webdav("#{dir}/upload.zip", :directory => File.basename(dir), :client => options[:client], :project => options[:project])
        ensure
          FileUtils.rm_rf dir
        end

        # kick the load
        pull = { 'pullIntegration' => File.basename(dir) }
        link = project.md.links('etl')['pull2']
        task = client.post(link, pull, :info_message => "Starting the data load from user storage to dataset '#{dataset}'.")

        res = client.poll_on_response(task['pull2Task']['links']['poll'], :info_message => 'Getting status of the dataload task.') do |body|
          body['wTaskStatus']['status'] == 'RUNNING' || body['wTaskStatus']['status'] == 'PREPARED'
        end

        if res['wTaskStatus']['status'] == 'ERROR' # rubocop:disable Style/GuardClause
          s = StringIO.new
          client.download_from_user_webdav(File.basename(dir) + '/upload_status.json', s, :client => client, :project => project)
          js = MultiJson.load(s.string)
          manifest_cols =  manifest['dataSetSLIManifest']['parts'].map { |c| c['columnName'] }

          # extract some human readable error message from the webdav file
          manifest_extra = manifest_cols - csv_header
          csv_extra = csv_header - manifest_cols

          error_message = begin
                            js['error']['message'] % js['error']['parameters']
                          rescue NoMethodError, ArgumentError
                            ''
                          end
          m = "Load failed with error '#{error_message}'.\n"
          m += "Columns that should be there (manifest) but aren't in uploaded csv: #{manifest_extra}\n" unless manifest_extra.empty?
          m += "Columns that are in csv but shouldn't be there (manifest): #{csv_extra}\n" unless csv_extra.empty?
          m += "Columns in the uploaded csv: #{csv_header}\n"
          m += "Columns in the manifest: #{manifest_cols}\n"
          m += "Original message:\n#{JSON.pretty_generate(js)}\n"
          m += "Manifest used for uploading:\n#{JSON.pretty_generate(manifest)}"
          fail m
        end
      end

      def merge_dataset_columns(a_schema_blueprint, b_schema_blueprint)
        a_schema_blueprint = a_schema_blueprint.to_hash
        b_schema_blueprint = b_schema_blueprint.to_hash
        d = GoodData::Helpers.deep_dup(a_schema_blueprint)
        d[:columns] = d[:columns] + b_schema_blueprint[:columns]
        d[:columns].uniq!
        columns_that_failed_to_merge = d[:columns].group_by { |x| [:reference, :date].include?(x[:type]) ? x[:dataset] : x[:id] }.map { |k, v| [k, v.count, v] }.select { |x| x[1] > 1 }
        unless columns_that_failed_to_merge.empty?
          columns_that_failed_to_merge.each do |error|
            GoodData.logger.error "Columns #{error[0]} failed to merge. There are #{error[1]} conflicting columns. When merging columns with the same name they have to be identical."
            GoodData.logger.error error[2]
          end
          fail "Columns #{columns_that_failed_to_merge.first} failed to merge. There are #{columns_that_failed_to_merge[1]} conflicting columns. #{columns_that_failed_to_merge[2]} When merging columns with the same name they have to be identical." unless columns_that_failed_to_merge.empty?
        end
        d
      end
    end
  end
end
