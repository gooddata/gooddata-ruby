require 'optparse'

example = 'Usage example: GD_ENV=testing GD_SPEC_PASSWORD= bundle exec ruby bin/test_projects_cleanup.rb'

options = {}
OptionParser.new do |opts|
  opts.banner = example
  opts.on('-f', '--force', 'Mercilessly deletes matching projects.') do |v|
    options[:force] = v
  end
  opts.on('-d N', '--days N', Integer, 'Number of days to keep projects for.') do |v|
    options[:days] = v
  end
  opts.on_tail("-h", "--help", "Show this message.") do
    puts opts
    exit 0
  end
end.parse!

require 'gooddata'
require_relative '../spec/environment/environment'
GoodData::Environment.load
config = GoodData::Environment::ConnectionHelper::LCM_ENVIRONMENT
secrets = GoodData::Environment::ConnectionHelper::SECRETS
default_domain = GoodData::Environment::ConnectionHelper::DEFAULT_DOMAIN

def delete_segment_by_title(title, segments, days = 14, force = false)
  return if segments.empty?
  dead_line = Time.now - days * 60 * 60 * 24

  filtered_segments = segments.select do |s|
    if s.id.match(title) && s.id.length > 14 && s.id[s.id.length-14..-1]
      segment_created = s.id[s.id.length-14..-1]
      created = Time.parse(segment_created) if segment_created

      s if created.year >= Time.new.year && created < dead_line
    end
  end

  filtered_segments.each do |segment|
    begin
      if force
        segment.clients.each do |segment_client|
          GoodData.logger.info("Deleting segment: #{segment.id} - client: #{segment_client.client_id}")
          segment_client.dissociate
        end

        puts "Deleting segment: #{segment.id}"
        segment && segment.delete(force: true)
      else
        puts "Would delete segment: #{segment.id}"
      end
    rescue RuntimeError, StandardError => ex
      puts "Failed to delete segment #{segment.id}, reason: #{ex}"
    end
  end
end

def delete_project_by_title(title, projects, days = 14, force = false)
  dead_line = Time.now - days * 60 * 60 * 24
  filtered_projects = projects.select do |p|
    p.title.match(title) && p.created < dead_line
  end
  filtered_projects.each do |project|
    begin
    if force
      puts "Deleting: #{project.pid} - #{project.title} - #{project.created}"
      project_add = project.add
      project_add && project_add.output_stage && project_add.output_stage.delete
      project.delete
    else
      puts "Would delete: #{project.pid} - #{project.title} - #{project.created}"
    end
    rescue StandardError => ex
      puts "Failed to delete project #{project.pid}, reason: #{ex}"
    end
  end
  puts "#{filtered_projects.length} projects matching \"#{title}\" #{'would be ' unless force}deleted."
end

def delete_ads_by_title(title, client, days = 14, force = false)
  warehouses = client.warehouses
  return if warehouses.empty?

  deleted = 0
  warehouses.each do |warehouse|
    warehouse_title = warehouse.title
    next unless warehouse_title.match(title)

    dead_line = Time.now - days * 60 * 60 * 24
    created = Time.parse(warehouse.data["created"])
    next if created > dead_line

    begin
      if force
        puts "Deleting: #{warehouse_title} - #{created}"
        warehouse.delete
      else
        puts "Would delete:  #{warehouse_title} - #{created}"
      end
      deleted += 1
    rescue StandardError => e
      puts "Failed to delete #{warehouse_title}: #{e}"
    end
  end
  puts "#{deleted} ADS instances with title \"#{title}\" #{'would be ' unless force}deleted."
end

def clean_up!(client, force, days, opts = {})
  projects = client.projects

  if opts[:domain_id]
    domain = client.domain(opts[:domain_id])

    # segments id format: {title}_{hostname}_{datetime}
    delete_segment_by_title(/CAR_DEMO_PREMIUM/, domain.segments, days, force)
  end

  delete_project_by_title(/Insurance Demo Master/, projects, days, force)
  delete_project_by_title(/Car Demo Master/, projects, days, force)
  delete_project_by_title(/Insurance Demo Workspace/, projects, days, force)
  delete_project_by_title(/Client With Conflicting LDM/, projects, days, force)
  delete_project_by_title(/Development Project/, projects, days, force)
  delete_project_by_title(/lcm-test-fixture/, projects, days, force)
  delete_project_by_title(/Test MASTER project/, projects, days, force)
  delete_project_by_title(/Test MINOR project/, projects, days, force)
  delete_project_by_title(/^Test project$/, projects, days, force)
  delete_project_by_title(/userprov-e2e-testing/, projects, days, force)
  delete_project_by_title(/load test service project/, projects, days, force)
  delete_project_by_title(/LCM SPEC PROJECT/, projects, days, force)
  delete_project_by_title(/LCM spec Client With Conflicting LDM Changes/, projects, days, force)
  delete_project_by_title(/LCM spec master project/, projects, days, force)
  delete_project_by_title(/users brick load test/, projects, days, force)
  delete_project_by_title(/transfer_processes and #transfer_schedules test/, projects, days, force)
  delete_project_by_title(/DailyUse Project for gooddata-ruby integration tests/, projects, days, force)
  delete_project_by_title(/^New project$/, projects, days, force)
  delete_project_by_title(/RubyGem Dev Week test/, projects, days, force)
  delete_project_by_title(/My project from blueprint/, projects, days, force)
  delete_ads_by_title(/Development ADS/, client, days, force)
  delete_ads_by_title(/Production ADS/, client, days, force)
  delete_ads_by_title(/TEST ADS/, client, days, force)
end

def init_client(username, password, server)
  GoodData.connect(
    username,
    password,
    server: server,
    verify_ssl: false,
    timeout: nil
  )
end

username = config[:username]
password = secrets[:password]
dev_client = init_client(username, password, "https://#{config[:dev_server]}")
prod_client = init_client(username, password, "https://#{config[:prod_server]}")

force = options[:force]
days = options[:days] || 3

clean_up!(dev_client, force, days)
clean_up!(prod_client, force, days, {domain_id: default_domain})

dev_client.disconnect
