# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe "Swapping a date dimension and exchanging all attributes/elements", :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper::create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.build("My project from blueprint") do |p|
      p.add_date_dimension('created_on')
      p.add_date_dimension('created_on_2')

      p.add_dataset('dataset.users') do |d|
        d.add_anchor('attr.users.id')
        d.add_label('label.users.id', reference: 'attr.users.id')
        d.add_date('created_on')
        d.add_fact('fact.users.some_number')
      end
    end

    # Create a project
    @project = @client.create_project_from_blueprint(@blueprint, token: ConnectionHelper::GD_PROJECT_TOKEN, environment: ProjectHelper::ENVIRONMENT)

    # Load data
    users_data = [
      ["label.users.id", "created_on", "fact.users.some_number"],
      [1,"01/01/2014",1],
      [2,"10/15/2014",2],
      [3,"05/02/2014",3]
    ]
    @project.upload(users_data, @blueprint, 'dataset.users')

  end

  after(:all) do
    @project.delete unless @project.nil?

    @client.disconnect
  end

  it "should swap the dimension, exhcange all stuff and not break anything" do

    # WE have 2 date dims
    expect(@blueprint.date_dimensions.map(&:id)).to eq ["created_on", "created_on_2"]
    # One is connected
    expect(@blueprint.datasets.flat_map(&:references).map(&:reference).include?('created_on')).to be_truthy
    # The other is disconnected
    expect(@blueprint.datasets.flat_map(&:references).map(&:reference).include?('created_on_2')).to be_falsey

    
    # Create a metric
    @metric_1 = @project.attributes('created_on.date').create_metric(title: 'Count of days in DD')
    @metric_1.save

    # Create a report
    @report = @project.create_report(left: @metric_1, top: ['created_on.date'], title: 'Beautiful report')
    @report.save

    def suggest_mapping(label_a, label_b, project)
      as = project.attributes
      a1 = as.select {|a| a.identifier.include?("#{label_a}.")}.pmapcat { |a| [a] + a.labels }
      a2 = as.select {|a| a.identifier.include?("#{label_b}.")}.pmapcat { |a| [a] + a.labels }
      a1.reduce({}) do |a, e|
        match = a2.find { |l| l.identifier.gsub(/^#{label_b}/, '') == e.identifier.gsub(/^#{label_a}/, '') }
        a[e.identifier] = match && match.identifier
        a
      end
    end

    # Create definition with report specific metric
    @metric_2 = @project.attributes('created_on.date').create_metric(title: 'Count of days in DD Secret')
    @metric_2.deprecated = true
    @metric_2.save
    @report_with_private = @project.create_report({
      left: @metric_2,
      top: ['created_on.day.in.week'],
      title: 'Beautiful report with private'
    })
    @report_with_private.save

    # Create a definition with a filter value
    @report = @project.create_report({
      left: @metric_2,
      top: ['created_on.quarter'],
      filters: [['created_on.year', 2015, 2016]],
      title: 'Beautiful report with filters'
    })
    @report.save

    @label = @project.labels('created_on.year').primary_label
    @variable = @project.create_variable(title: 'uaaa', attribute: @label.attribute).save    
    filters = [[ConnectionHelper::DEFAULT_USERNAME, @label.uri, '2015', '2016']]
    @project.add_variable_permissions(filters, @variable)
    
    as = @project.attributes.select {|a| a.identifier.include?('created_on_2.')}
    expect(as.pmapcat {|a| a.usedby('report')}).to be_empty
    expect(as.pmapcat {|a| a.usedby('metric')}).to be_empty
    expect(as.pmapcat {|a| a.usedby('dashboard')}).to be_empty

    # replace values
    mapping = GoodData::Helpers.prepare_mapping(suggest_mapping('created_on', 'created_on_2', @project), project: @project)
    @project.replace_from_mapping(mapping)

    # Check if any of the attributes is used by any of the objects. All should be empty
    as = @project.attributes.select {|a| a.identifier.include?('created_on.')}
    expect(as.pmapcat {|a| a.usedby('report')}).to be_empty
    expect(as.pmapcat {|a| a.usedby('metric')}).to be_empty
    expect(as.pmapcat {|a| a.usedby('dashboard')}).to be_empty

    # Reload stuff
    @metric_2.reload!
    @report.reload!
    @report_with_private.reload!

    # Stuff should be still computable
    @metric_2.execute
    @report.execute
    @report_with_private.execute

    # Labels 
    GoodData::SmallGoodZilla.get_uris(@metric_2.expression)
    expect(@report.definition.attributes.map(&:identifier)).to eq ["created_on_2.quarter"]
    ids = GoodData::SmallGoodZilla.get_uris(@report.definition.filters.first).map { |x| x.split('/')[-2..-1].join('/') }
    expect(ids).to eq ["obj/2286", "2286/elements?id=2015", "2286/elements?id=2016"]

    ids = GoodData::SmallGoodZilla.get_uris(@report.definition.filters.first).map { |x| x.split('/')[-2..-1].join('/') }
    expect(ids).to eq ["obj/2286", "2286/elements?id=2015", "2286/elements?id=2016"]

    ids = GoodData::SmallGoodZilla.get_uris(@variable.values.first.expression).map {|v| v.split('/')[-2..-1].join('/')}
    expect(ids).to eq ["obj/2286", "2286/elements?id=2015", "2286/elements?id=2016"]

    # Swap the dims
    bp = @project.blueprint
    bp.swap_date_dimension!('created_on', 'created_on_2')
    @project.update_from_blueprint(bp)
    expect(bp.datasets.flat_map(&:references).map(&:reference).include?('created_on')).to be_falsey
    expect(bp.datasets.flat_map(&:references).map(&:reference).include?('created_on_2')).to be_truthy
  end
end