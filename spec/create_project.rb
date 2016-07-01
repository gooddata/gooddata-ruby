# encoding: utf-8

require 'gooddata'

GoodData.with_connection('tomas.korcak+gem_tester@gooddata.com', 'jindrisska', :server => 'https://staging3.intgdc.com') do |client|
  blueprint = GoodData::Model::ProjectBlueprint.build('Acme project') do |p|
    p.add_date_dimension('committed_on')
    p.add_dataset('devs') do |d|
      d.add_anchor('attr.dev')
      d.add_label('label.dev_id', :reference => 'attr.dev')
      d.add_label('label.dev_email', :reference => 'attr.dev')
    end
    p.add_dataset('commits') do |d|
      d.add_anchor('attr.commits_id')
      d.add_fact('fact.lines_changed')
      d.add_date('committed_on')
      d.add_reference('devs')
    end
  end
  project = GoodData::Project.create_from_blueprint(blueprint, auth_token: 'OCTOCAT')
  puts "Created project #{project.pid}"
  puts project.inspect

  # Load data
  commits_data = [
    ['fact.lines_changed', 'committed_on', 'devs'],
    [1, '01/01/2014', 1],
    [3, '01/02/2014', 2],
    [5, '05/02/2014', 3]]
  project.upload(commits_data, blueprint, 'commits')

  devs_data = [
    ['label.dev_id', 'label.dev_email'],
    [1, 'tomas@gooddata.com'],
    [2, 'petr@gooddata.com'],
    [3, 'jirka@gooddata.com']]
  project.upload(devs_data, blueprint, 'devs')

  # create a metric
  metric = project.facts('fact.lines_changed').create_metric
  metric.save
  report = project.create_report(title: 'Awesome_report', top: [metric], left: ['label.dev_email'])
  report.save

  process_path = File.expand_path("../data/hello_world_process/hello_world.zip", __FILE__)
  process = project.deploy_process(process_path, name: 'Test ETL Process', type: 'RUBY')
  puts process.inspect

  begin
    schedule = process.create_schedule('0 0 1 1 *', 'hello_world.rb')
    puts schedule.inspect
  rescue => e
    puts e.inspect
  end


  project.delete
end