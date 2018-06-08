# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
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
          opts = { client: GoodData.connection, execute_ca_scripts: true, only_model: false }.merge(opts)
          client = opts[:client]
          fail ArgumentError, 'No :client specified' if client.nil?

          spec = opts[:spec] || fail('You need to provide spec for migration')
          bp = ProjectBlueprint.new(spec)
          fail GoodData::ValidationError, "Blueprint is invalid #{bp.validate.inspect}" unless bp.valid?
          spec = bp.to_hash

          project = opts[:project] || client.create_project(opts.merge(:title => opts[:title] || spec[:title], :client => client, :environment => opts[:environment]))

          maqls = migrate_datasets(spec, opts.merge(project: project, client: client))
          load(p, spec)
          migrate_metrics(p, spec[:metrics] || []) unless opts[:only_model]
          migrate_reports(p, spec[:reports] || []) unless opts[:only_model]
          migrate_dashboards(p, spec[:dashboards] || []) unless opts[:only_model]
          execute_tests(p, spec[:assert_tests] || [])
          opts[:execute_ca_scripts] ? project : maqls.find { |maql| maql.key?('maqlDdlChunks') }
        end

        def migrate_datasets(spec, opts = {})
          opts = { client: GoodData.connection }.merge(opts)
          dry_run = opts[:dry_run]
          replacements = opts['maql_replacements'] || opts[:maql_replacements] || {}

          _, project = GoodData.get_client_and_project(opts)

          bp = ProjectBlueprint.new(spec)
          maql_diff_params = [:includeGrain]
          maql_diff_params << :excludeFactRule if opts[:exclude_fact_rule]
          response = project.maql_diff(blueprint: bp, params: maql_diff_params)

          GoodData.logger.debug("projectModelDiff") { response.pretty_inspect }
          chunks = response['projectModelDiff']['updateScripts']
          return [] if chunks.empty?

          ca_maql = response['projectModelDiff']['computedAttributesScript'] if response['projectModelDiff']['computedAttributesScript']
          ca_chunks = ca_maql && ca_maql['maqlDdlChunks']

          maqls = pick_correct_chunks(chunks, opts)
          replaced_maqls = apply_replacements_on_maql(maqls, replacements)

          unless dry_run
            errors = []
            replaced_maqls.each do |replaced_maql_chunks|
              begin
                replaced_maql_chunks['updateScript']['maqlDdlChunks'].each do |chunk|
                  GoodData.logger.debug(chunk)
                  project.execute_maql(chunk)
                end
              rescue => e
                puts "Error occured when executing MAQL, project: \"#{project.title}\" reason: \"#{e.message}\", chunks: #{replaced_maql_chunks.inspect}"
                errors << e
                next
              end
            end

            if ca_chunks && opts[:execute_ca_scripts]
              begin
                ca_chunks.each { |chunk| project.execute_maql(chunk) }
              rescue => e
                puts "Error occured when executing MAQL, project: \"#{project.title}\" reason: \"#{e.message}\", chunks: #{ca_chunks.inspect}"
                errors << e
              end
            end

            if (!errors.empty?) && (errors.length == replaced_maqls.length)
              messages = errors.map { |err| GoodData::Helpers.interpolate_error_messages(err.data['wTaskStatus']['messages']) }
              fail "Unable to migrate LDM, reason(s): \n #{messages.join("\n")}"
            end
          end
          replaced_maqls + (ca_maql ? [ca_maql] : [])
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
          GoodData.logger.debug("update_preference") { opts[:update_preference].pretty_inspect }
          preference = GoodData::Helpers.symbolize_keys(opts[:update_preference] || {})
          preference = Hash[preference.map { |k, v| [k, GoodData::Helpers.to_boolean(v)] }]

          # will use new parameters instead of the old ones
          if preference.empty? || [:allow_cascade_drops, :keep_data].any? { |k| preference.key?(k) }
            if [:cascade_drops, :preserve_data].any? { |k| preference.key?(k) }
              fail "Please do not mix old parameters (:cascade_drops, :preserve_data) with the new ones (:allow_cascade_drops, :keep_data)."
            end
            preference = { allow_cascade_drops: false, keep_data: true }.merge(preference)

            new_preference = {}
            new_preference[:cascade_drops] = false unless preference[:allow_cascade_drops]
            new_preference[:preserve_data] = true if preference[:keep_data]
            preference = new_preference
          end

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
            { cascade_drops: chunk['updateScript']['cascadeDrops'],
              preserve_data: chunk['updateScript']['preserveData'],
              maql: chunk['updateScript']['maqlDdlChunks'],
              orig: chunk }
          end

          results_from_api = GoodData::Helpers.join(
            rules,
            stuff,
            [:cascade_drops, :preserve_data],
            [:cascade_drops, :preserve_data],
            inner: true
          ).sort_by { |l| l[:priority] } || []

          if preference.empty?
            [results_from_api.first[:orig]]
          else
            results = results_from_api.dup
            preference.each do |k, v|
              results = results.select do |result|
                result[k] == v
              end
            end
            if results.empty?
              available_chunks = results_from_api
                                    .map do |result|
                                      {
                                        cascade_drops: result[:cascade_drops],
                                        preserve_data: result[:preserve_data]
                                      }
                                    end
                                    .map(&:to_s)
                                    .join(', ')
              fail "Synchronize LDM cannot proceed. Adjust your update_preferences and try again. Available chunks with preference: #{available_chunks}"
            end
            results.map { |result| result[:orig] }
          end
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
