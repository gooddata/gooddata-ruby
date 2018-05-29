require 'fileutils'

class ConfigurationHelper
  class << self
    CACHE_DIR = 'spec/cache/dev_projects/'

    def suffix
      hostname = Socket.gethostname
      timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
      suffix = "#{hostname}_#{timestamp}"
      segment_name_forbidden_chars = /[^a-zA-Z0-9_\\-]+/
      suffix.scan(segment_name_forbidden_chars).each do |forbidden_characters|
        suffix.gsub!(forbidden_characters, '_')
      end
      suffix
    end

    def create_interpolated_tempfile(path, args)
      res = GoodData::Helpers::ErbHelper.template_file(path, args)

      file = Tempfile.new(File.basename(path), Dir.tmpdir)
      path = file.path

      file.write(res)
      file.rewind
      file.close

      path
    end

    def csv_from_hashes(hashes)
      temp_file = Tempfile.new('users_csv')

      if hashes.empty?
        File.open(temp_file, 'w') {}
      else
        CSV.open(temp_file, 'w', write_headers: true, headers: hashes.first.keys) do |csv|
          hashes.each { |hash| csv << hash }
        end
      end
      temp_file
    end

    def create_development_datawarehouse(opts = {})
      datawarehouse = GoodData::DataWarehouse.create(opts)
      GoodData.logger.info("Datawarehouse ID: #{datawarehouse.obj_id}")
      datawarehouse
    end

    def ensure_development_project(opts = {})
      if $reuse_project
        begin
          project_id = File.read(CACHE_DIR + LcmConnectionHelper.env_name).chomp
          project = opts[:client].projects(project_id)
          GoodData.logger.info("Reusing development project ID: #{project_id}")
          Support::ProjectHelper.new(project, opts)
        rescue Errno::ENOENT, RestClient::NotFound, RestClient::Gone
          $reuse_project = false
          helper = create_development_project(opts)
          FileUtils.mkpath CACHE_DIR
          File.write(CACHE_DIR + LcmConnectionHelper.env_name, helper.project.pid)
          helper
        end
      else
        return create_development_project(opts)
      end
    end

    def create_development_project(opts = {})
      project_helper = Support::ProjectHelper.create(opts)
      project_helper.create_ldm
      project_helper.load_data
      project_helper.create_metrics
      project_helper.create_computed_attributes
      project_helper.create_reports
      project_helper.create_dashboards
      project_helper.create_tag_for_fact_n_dataset
      project_helper.add_user_group
      project_helper
    end

    def create_output_stage_project(rest_client, suffix, ads, token, environment)
      project = rest_client.create_project(
        client: rest_client,
        title: "Output Stage Project #{suffix}",
        auth_token: token,
        environment: environment,
        ads: ads
      )
      project.create_output_stage(
        ads,
        project: project,
        client: rest_client
      )
      project
    end
  end
end
