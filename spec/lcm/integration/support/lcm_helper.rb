class LcmHelper
  class << self
    def create_release_table(name, ads_client)
      query = 'CREATE TABLE IF NOT EXISTS "LCM_RELEASE" (segment_id VARCHAR(255) NOT NULL, master_project_id VARCHAR(255) NOT NULL, version INTEGER NOT NULL, maql_ddl VARCHAR(65000));'
      query.gsub!('LCM_RELEASE', name)
      ads_client.execute(query)
    end

    def create_workspace_table(name, ads_client, client_id_column = 'client_id')
      query = 'CREATE TABLE IF NOT EXISTS "LCM_WORKSPACE" (client_id VARCHAR(255) NOT NULL, segment_id VARCHAR(255) NOT NULL, project_id VARCHAR(255), project_title VARCHAR(255) NOT NULL);'
      query.gsub!('LCM_WORKSPACE', name)
           .gsub!('client_id', client_id_column)
      ads_client.execute(query)
    end

    def create_suffix
      hostname = Socket.gethostname
      timestamp = DateTime.now.strftime('%Y%m%d%H%M%S')
      suffix = "#{hostname}_#{timestamp}"
      segment_name_forbidden_chars = /[^a-zA-Z0-9_\\-]+/
      suffix.scan(segment_name_forbidden_chars).each do |forbidden_characters|
        suffix.gsub!(forbidden_characters, '_')
      end
      suffix
    end

    def create_workspace_csv(workspaces, client_id_column)
      temp_file = Tempfile.new('workspace_csv')
      headers = [client_id_column, 'segment_id', 'project_title']

      CSV.open(temp_file, 'w', write_headers: true, headers: headers) do |csv|
        workspaces.each do |workspace|
          csv << [workspace[:client_id],
                  workspace[:segment_id],
                  workspace[:title]]
        end
      end
      temp_file
    end
  end
end
