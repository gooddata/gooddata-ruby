# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require_relative 'project'
require_relative 'blueprint/project_blueprint'

require 'open-uri'

module GoodData
  module Model
    class ProjectCreator
      class << self
        def migrate(opts = {})
          opts = { client: GoodData.connection }.merge(opts)
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          spec = opts[:spec] || fail('You need to provide spec for migration')
          bp = ProjectBlueprint.new(spec)
          fail GoodData::ValidationError, "Blueprint is invalid #{bp.validate.inspect}" unless bp.valid?
          spec = bp.to_hash

          project = opts[:project] || client.create_project(opts.merge(:title => spec[:title], :client => client, :environment => opts[:environment]))

          begin
            migrate_datasets(spec, opts.merge(project: project, client: client))
            load(p, spec)
            migrate_metrics(p, spec[:metrics] || [])
            migrate_reports(p, spec[:reports] || [])
            migrate_dashboards(p, spec[:dashboards] || [])
            execute_tests(p, spec[:assert_tests] || [])
            project
          end
        end

        def migrate_datasets(spec, opts = {})
          opts = { client: GoodData.connection }.merge(opts)
          dry_run = opts[:dry_run]
          replacements = opts['maql_replacements'] || opts[:maql_replacements] || {}

          client, project = GoodData.get_client_and_project(opts)

          bp = ProjectBlueprint.new(spec)

          uri = "/gdc/projects/#{project.pid}/model/diff?includeGrain=true"
          result = client.post(uri, bp.to_wire)
          response = client.poll_on_code(result['asyncTask']['link']['poll'])

          maqls = pick_correct_chunks(response['projectModelDiff']['updateScripts'], opts)
          replaced_maqls = apply_replacements_on_maql(maqls, replacements)

          unless dry_run
            errors = []
            replaced_maqls.each do |replaced_maql_chunks|
              begin
                replaced_maql_chunks['updateScript']['maqlDdlChunks'].each { |chunk| project.execute_maql(chunk) }
              rescue => e
                puts "Error occured when executing MAQL, project: \"#{project.title}\" reason: \"#{e.message}\", chunks: #{replaced_maql_chunks.inspect}"
                errors << e
                next
              end
            end
            if (!errors.empty?) && (errors.length == replaced_maqls.length)
              messages = errors.map { |e| GoodData::Helpers.interpolate_error_messages(e.data['wTaskStatus']['messages']) }
              fail "Unable to migrate LDM, reason(s): \n #{messages.join("\n")}"
            end
          end
          replaced_maqls
        end

        def migrate_reports(project, spec)
          spec.each do |report|
            project.add_report(report)
          end
        end

        def migrate_dashboards(project, spec)
          spec.each do |dash|
            project.add_dashboard(dash)
          end
        end

        def migrate_metrics(project, spec)
          spec.each do |metric|
            project.add_metric(metric)
          end
        end

        alias_method :migrate_measures, :migrate_metrics

        def load(project, spec)
          if spec.key?(:uploads) # rubocop:disable Style/GuardClause
            spec[:uploads].each do |load|
              schema = GoodData::Model::Schema.new(spec[:datasets].find { |d| d[:name] == load[:dataset] })
              project.upload(load[:source], schema, load[:mode])
            end
          end
        end

        def execute_tests(_project, spec)
          spec.each do |assert|
            result = GoodData::ReportDefinition.execute(assert[:report])
            fail "Test did not pass. Got #{result.table.inspect}, expected #{assert[:result].inspect}" if result.table != assert[:result]
          end
        end

        def pick_correct_chunks(chunks, opts = {})
          preference = GoodData::Helpers.symbolize_keys(opts[:update_preference] || {})

          # first is cascadeDrops, second is preserveData
          rules = [
            { priority: 1, cascade_drops: false, preserve_data: true },
            { priority: 2, cascade_drops: false, preserve_data: false },
            { priority: 3, cascade_drops: true, preserve_data: true },
            { priority: 4, cascade_drops: true, preserve_data: false }
          ]

          stuff = chunks.select do |chunk|
            chunk['updateScript']['maqlDdlChunks']
          end

          stuff = stuff.map do |chunk|
            { cascade_drops: chunk['updateScript']['cascadeDrops'], preserve_data: chunk['updateScript']['preserveData'], maql: chunk['updateScript']['maqlDdlChunks'], orig: chunk }
          end

          results = GoodData::Helpers.join(rules, stuff, [:cascade_drops, :preserve_data], [:cascade_drops, :preserve_data], inner: true).sort_by { |l| l[:priority] } || []

          preference.each do |k, v|
            results = results.find_all do |result|
              result[k] == v
            end
          end
          (preference.empty? ? [results.first].compact : results).map { |result| result[:orig] }
        end

        private

        def apply_replacements_on_maql(maqls, replacements = {})
          maqls.map do |maql|
            GoodData::Helpers.deep_dup(maql).tap do |m|
              m['updateScript']['maqlDdlChunks'] = m['updateScript']['maqlDdlChunks'].map do |chunk|
                replacements.reduce(chunk) { |a, (k, v)| a.gsub(Regexp.new(k), v) }
              end
            end
          end
        end
      end
    end
  end
end
