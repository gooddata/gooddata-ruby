# encoding: UTF-8
#
# Copyright (c) 2010-2015 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata'

describe 'Create project using GoodData client', :constraint => 'slow' do
  before(:all) do
    @client = ConnectionHelper.create_default_connection
    @blueprint = GoodData::Model::ProjectBlueprint.build("My project from blueprint") do |p|
      p.add_date_dimension('created_on')

      p.add_dataset('dataset.users') do |d|
        d.add_anchor('attr.users.id', grain: [{ date: 'created_on' }, { attribute: 'attribute.user' }])
        d.add_date('created_on')
        d.add_attribute('attribute.user')
        d.add_label('label.user.email', reference: 'attribute.user')
        d.add_fact('fact.users.some_number')
      end
    end
    @blueprint.valid? # => true

    @project = @client.create_project_from_blueprint(@blueprint, auth_token: ConnectionHelper::GD_PROJECT_TOKEN)
  end

  after(:all) do
    @project.delete
    @client.disconnect
  end

  it 'Should load the data with grain' do
    data = [
      ['created_on', 'label.user.email', 'fact.users.some_number'],
      ['01/01/2011', 'thomas', '1'],
      ['01/01/2011', 'thomas', '2'],
      ['01/01/2011', 'jim', '2'],
      ['01/01/2011', 'peter', '2'],
      ['01/01/2011', 'john', '3']]
    @project.upload(data, @blueprint, 'dataset.users')

    expect(@project.blueprint.datasets.first.count(@project)).to eq 4
  end

  it 'Should be able to remove grain and load the same data' do
    updated_blueprint = GoodData::Model::ProjectBlueprint.build("My project from blueprint") do |p|
      p.add_date_dimension('created_on')

      p.add_dataset('dataset.users') do |d|
        d.add_anchor('attr.users.id')
        d.add_date('created_on')
        d.add_attribute('attribute.user')
        d.add_label('label.user.email', reference: 'attribute.user')
        d.add_fact('fact.users.some_number')
      end
    end

    @project.update_from_blueprint(updated_blueprint)

    data = [
      ['created_on', 'label.user.email', 'fact.users.some_number'],
      ['01/01/2011', 'thomas', '1'],
      ['01/01/2011', 'thomas', '2'],
      ['01/01/2011', 'jim', '2'],
      ['01/01/2011', 'peter', '2'],
      ['01/01/2011', 'john', '3']]
    @project.upload(data, @blueprint, 'dataset.users')

    expect(@project.blueprint.datasets.first.count(@project)).to eq 5
  end
end
