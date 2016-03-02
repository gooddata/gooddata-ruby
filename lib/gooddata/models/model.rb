# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

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
        data = [
          {
            data: path,
            dataset: dataset,
            options: options
          }
        ]
        GoodData::Model.upload_multiple_data(data, project_blueprint, options)
      end

      # Uploads multiple data sets using batch upload interface
      # @param data [String|Array] Input data
      # @param project_blueprint [ProjectBlueprint] Project blueprint
      # @param options [Hash] Additional options
      # @return [Hash] Batch upload result
      def upload_multiple_data(data, project_blueprint, options = { :client => GoodData.connection, :project => GoodData.project })
        client, project = GoodData.get_client_and_project(options)

        project ||= GoodData.project

        manifest = {

          'dataSetSLIManifestList' => data.map do |d|
            mode = d[:options] && d[:options][:mode] ? d[:options][:mode] : options[:mode] || 'FULL'
            GoodData::Model::ToManifest.dataset_to_manifest(project_blueprint, d[:dataset], mode)
          end
        }

        csv_headers = []

        # create a temporary zip file
        dir = Dir.mktmpdir
        begin
          Zip::File.open("#{dir}/upload.zip", Zip::File::CREATE) do |zip|
            # TODO: make sure schema columns match CSV column names
            zip.get_output_stream('upload_info.json') { |f| f.puts JSON.pretty_generate(manifest) }

            data.zip(manifest['dataSetSLIManifestList']).each do |item|
              path = item[0][:data]
              path = item[0][:data].path if item[0][:data].respond_to? :path
              inline_data = path.is_a?(String) ? false : true
              csv_header = nil

              filename = item[1]['dataSetSLIManifest']['file']

              if inline_data
                csv_header = path.first
                zip.get_output_stream(filename) do |f|
                  path.each do |row|
                    f.puts row.to_csv
                  end
                end
              else
                csv_header = File.open(path, &:gets).split(',')
                zip.add(filename, path)
              end

              csv_headers << csv_header
            end
          end

          # upload it
          client.upload_to_user_webdav("#{dir}/upload.zip", :directory => File.basename(dir), :client => options[:client], :project => options[:project])
        ensure
          FileUtils.rm_rf dir
        end
        csv_headers.flatten!

        # kick the load
        pull = { 'pullIntegration' => File.basename(dir) }
        link = project.md.links('etl')['pull2']

        # TODO: List uploaded datasets
        task = client.post(link, pull, :info_message => 'Starting the data load from user storage to dataset.')

        res = client.poll_on_response(task['pull2Task']['links']['poll'], :info_message => 'Getting status of the dataload task.') do |body|
          body['wTaskStatus']['status'] == 'RUNNING' || body['wTaskStatus']['status'] == 'PREPARED'
        end

        if res['wTaskStatus']['status'] == 'ERROR'
          s = StringIO.new

          messages = res['wTaskStatus']['messages'] || []
          messages.each do |msg|
            GoodData.logger.error(JSON.pretty_generate(msg))
          end

          begin
            client.download_from_user_webdav(File.basename(dir) + '/upload_status.json', s, :client => client, :project => project)
          rescue => e
            raise "Unable to download upload_status.json from remote server, reason: #{e.message}"
          end

          js = MultiJson.load(s.string)
          manifests = manifest['dataSetSLIManifestList'].map do |m|
            m['dataSetSLIManifest']
          end

          parts = manifests.map do |m|
            m['parts']
          end

          manifest_cols = parts.flatten.map { |c| c['columnName'] }

          # extract some human readable error message from the webdav file
          manifest_extra = manifest_cols - csv_headers
          csv_extra = csv_headers - manifest_cols

          error_message = begin
            js['error']['message'] % js['error']['parameters']
          rescue NoMethodError, ArgumentError
            ''
          end
          m = "Load failed with error '#{error_message}'.\n"
          m += "Columns that should be there (manifest) but aren't in uploaded csv: #{manifest_extra}\n" unless manifest_extra.empty?
          m += "Columns that are in csv but shouldn't be there (manifest): #{csv_extra}\n" unless csv_extra.empty?
          m += "Columns in the uploaded csv: #{csv_headers}\n"
          m += "Columns in the manifest: #{manifest_cols}\n"
          m += "Original message:\n#{JSON.pretty_generate(js)}\n"
          m += "Manifest used for uploading:\n#{JSON.pretty_generate(manifest)}"
          fail m
        end

        res
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
