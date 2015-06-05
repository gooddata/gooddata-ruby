# encoding: UTF-8

require_relative '../core/rest'

require_relative 'metadata/metadata'

require_relative 'links'
require_relative 'module_constants'
require_relative 'user_filters/user_filters'

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
    GD_TYPES = %w(GDC.link GDC.text GDC.geo GDC.time)
    GD_DATA_TYPES = %w(INT VARCHAR DECIMAL)

    DEFAULT_FACT_DATATYPE = 'INT'

    class << self
      def title(item)
        item[:title] || item[:name].titleize
      end

      def description(item)
        item[:description]
      end

      def identifier_for(dataset, column = nil, column2 = nil) # rubocop:disable UnusedMethodArgument
        return "dataset.#{dataset[:name]}" if column.nil?
        column = DatasetBlueprint.find_column_by_name(dataset, column) if column.is_a?(String)
        case column[:type].to_sym
        when :anchor_no_label
          "attr.#{dataset[:name]}.factsof"
        when :attribute
          "attr.#{dataset[:name]}.#{column[:name]}"
        when :anchor
          "attr.#{dataset[:name]}.#{column[:name]}"
        when :date_fact
          "dt.#{dataset[:name]}.#{column[:name]}"
        when :fact
          "fact.#{dataset[:name]}.#{column[:name]}"
        when :primary_label
          "label.#{dataset[:name]}.#{column[:name]}"
        when :label
          "label.#{dataset[:name]}.#{column[:reference]}.#{column[:name]}"
        when :date_ref
          "#{dataset[:name]}.date.mdyy"
        when :dataset
          "dataset.#{dataset[:name]}"
        when :date
          'DATE'
        when :reference
          'REF'
        else
          fail "Unknown type #{column[:type].to_sym}"
        end
      end

      def check_gd_datatype(value)
        GD_TYPES.any? { |v| v == value }
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

        # create a temporary zip file
        dir = Dir.mktmpdir
        begin
          Zip::File.open("#{dir}/upload.zip", Zip::File::CREATE) do |zip|
            # TODO: make sure schema columns match CSV column names
            zip.get_output_stream('upload_info.json') { |f| f.puts JSON.pretty_generate(manifest) }
            if inline_data
              zip.get_output_stream('data.csv') do |f|
                path.each do |row|
                  f.puts row.to_csv
                end
              end
            else
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
        link = project.md.links('etl')['pull']
        task = client.post link, pull

        res = client.poll_on_response(task['pullTask']['uri']) do |body|
          body['taskStatus'] == 'RUNNING' || body['taskStatus'] == 'PREPARED'
        end

        if res['taskStatus'] == 'ERROR' # rubocop:disable Style/GuardClause
          s = StringIO.new
          client.download_from_user_webdav(File.basename(dir) + '/upload_status.json', s, :client => client, :project => project)
          js = MultiJson.load(s.string)
          fail "Load Failed with error #{JSON.pretty_generate(js)}"
        end
      end

      def merge_dataset_columns(a_schema_blueprint, b_schema_blueprint)
        a_schema_blueprint = a_schema_blueprint.to_hash
        b_schema_blueprint = b_schema_blueprint.to_hash
        d = a_schema_blueprint.deep_dup
        d[:columns] = d[:columns] + b_schema_blueprint[:columns]
        d[:columns].uniq!
        columns_that_failed_to_merge = d[:columns].group_by { |x| x[:name] }.map { |k, v| [k, v.count] }.select { |x| x[1] > 1 }
        fail "Columns #{columns_that_failed_to_merge} failed to merge. When merging columns with the same name they have to be identical." unless columns_that_failed_to_merge.empty?
        d
      end
    end
  end
end
