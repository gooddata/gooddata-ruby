# encoding: UTF-8

require_relative '../core/connection'
require_relative '../core/rest'

require_relative 'attributes/attributes'
require_relative 'columns/columns'
require_relative 'facts/facts'
require_relative 'folders/folders'
require_relative 'metadata/metadata'
require_relative 'references/references'

require_relative 'links'
require_relative 'module_constants'
require_relative 'metadata/schema'

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
    class << self
      def add_dataset(name, columns, project = nil)
        Schema.new('columns' => columns, 'name' => name)
        add_schema(schema, project)
      end

      def add_schema(schema, project = nil)
        unless schema.respond_to?(:to_maql_create) || schema.is_a?(String) then
          raise ArgumentError.new("Schema object or schema file path expected, got '#{schema}'")
        end
        schema = Schema.load(schema) unless schema.respond_to?(:to_maql_create)
        project = GoodData.project unless project
        ldm_links = GoodData.get project.md[LDM_CTG]
        ldm_uri = Links.new(ldm_links)[LDM_MANAGE_CTG]
        GoodData.post ldm_uri, {'manage' => {'maql' => schema.to_maql_create}}
      end

      # Load given file into a data set described by the given schema
      def upload_data(path, manifest, options={})
        project = options[:project] || GoodData.project
        # mode = options[:mode] || "FULL"
        path = path.path if path.respond_to? :path
        inline_data = path.is_a?(String) ? false : true

        # create a temporary zip file
        dir = Dir.mktmpdir
        begin
          Zip::File.open("#{dir}/upload.zip", Zip::File::CREATE) do |zip|
            # TODO make sure schema columns match CSV column names
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
          GoodData.upload_to_user_webdav("#{dir}/upload.zip", :directory => File.basename(dir))
        ensure
          FileUtils.rm_rf dir
        end

        # kick the load
        pull = {'pullIntegration' => File.basename(dir)}
        link = project.md.links('etl')['pull']
        task = GoodData.post link, pull
        while GoodData.get(task['pullTask']['uri'])['taskStatus'] === 'RUNNING' || GoodData.get(task['pullTask']['uri'])['taskStatus'] === 'PREPARED'
          sleep 30
        end
        if GoodData.get(task['pullTask']['uri'])['taskStatus'] == 'ERROR'
          s = StringIO.new
          GoodData.download_from_user_webdav(File.basename(dir) + '/upload_status.json', s)
          js = MultiJson.load(s.string)
          fail "Load Failed with error #{JSON.pretty_generate(js)}"
        end
      end

      def merge_dataset_columns(a_schema_blueprint, b_schema_blueprint)
        a_schema_blueprint = a_schema_blueprint.to_hash
        b_schema_blueprint = b_schema_blueprint.to_hash
        d = Marshal.load(Marshal.dump(a_schema_blueprint))
        d[:columns] = d[:columns] + b_schema_blueprint[:columns]
        d[:columns].uniq!
        columns_that_failed_to_merge = d[:columns].group_by { |x| x[:name] }.map { |k, v| [k, v.count] }.find_all { |x| x[1] > 1 }
        fail "Columns #{columns_that_failed_to_merge} failed to merge. When merging columns with the same name they have to be identical." unless columns_that_failed_to_merge.empty?
        d
      end
    end
  end
end