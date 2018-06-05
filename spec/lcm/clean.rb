#! /usr/bin/env ruby

require 'gooddata'

def read_params(_args = ARGV)
  params_path = File.expand_path('../integration/params/global.json', __FILE__)
  params = (File.exist?(params_path) && JSON.parse(File.read(params_path))) || {}
  GoodData::Helpers.deep_symbolize_keys(params)
end


def connect(params)
  GoodData.connect(params[:username], params[:password], server: params[:server], verify_ssl: params[:verify_ssl])
end

def delete_masters(client, params)
  client.projects.each do |project|
    if project.title.start_with?(params[:master_prefix])
      GoodData.logger.info("Deleting Master Project, title: '#{project.title}', PID: '#{project.pid}'")
      project.delete
    end
  end
end

def delete_segments(client, params)
  domain = client.domain(params[:organization] || params[:domain])

  domain.segments.each do |segment|
    GoodData.logger.info("Deleting segment '#{segment.segment_id}'")

    segment.clients.each do |segment_client|
      GoodData.logger.info("Deleting client '#{segment_client.client_id}'")

      project = segment_client.project
      unless project.nil? || project.deleted?
        GoodData.logger.info("Deleting client project '#{project.title}'")
        project.delete
      end

      segment_client.delete
    end

    segment.delete
  end
end

def main(args = ARGV)
  params = read_params(args)
  client = connect(params)
  delete_masters(client, params)
  delete_segments(client, params)
end

if $PROGRAM_NAME == __FILE__
  main(ARGV)
end
