begin
  client = GoodData.connect <USERNAME>, <PASSWORD>, server: <SERVER>, verify_ssl: false
  bp = GoodData::Model::ProjectBlueprint.build("Xen's project from blueprint CA") do |project_builder|
    project_builder.add_date_dimension('created_on')

    project_builder.add_dataset('dataset.users', title: 'Users Dataset') do |schema_builder|
      schema_builder.add_anchor('attr.users.id', title: 'Users ID', folder: 'Users ID folder')
      schema_builder.add_label('label.users.id_label1', reference: 'attr.users.id')
      schema_builder.add_label('label.users.id_label2', reference: 'attr.users.id', default_label: true)
      schema_builder.add_attribute('attr.users.another_attr', title: 'Another attr')
      schema_builder.add_label('label.users.another_attr_label', reference: 'attr.users.another_attr')
      schema_builder.add_date('created_on')
      schema_builder.add_fact('fact.users.some_number')
    end
  end

  unless bp.valid?
    pp bp.validate
    fail "Origin blueprint is not valid"
  end

  project = client.create_project_from_blueprint(bp, auth_token: <TOKEN>, environment: 'TESTING')
  puts "Created project: #{project.pid}"

  metric = project.facts('fact.users.some_number').create_metric(title: 'Test')
  metric.save

  attribute = project.attributes('attr.users.another_attr')
  fail "is a CA" if attribute.computed_attribute?

  update = GoodData::Model::ProjectBlueprint.build('update') do |project_builder|
    project_builder.add_computed_attribute(
      'attr.comp.my_computed_attr',
      title: 'My computed attribute',
      metric: metric,
      attribute: attribute,
      buckets: [{ label: 'Xen', highest_value: 1000 }, { label: 'Ken', highest_value: 2000 }, { label: 'Kute', highest_value: 3000 }, { label: 'Olala' }]
    )
  end

  new_bp = bp.merge(update)

  unless new_bp.valid?
    pp new_bp.validate
    fail "New blueprint is not valid"
  end

  project.update_from_blueprint(new_bp)
  ca = project.attributes.find { |a| a.title == 'My computed attribute' }
  fail "CA is nil" unless ca
  fail "not a CA" unless ca.computed_attribute?
  puts project.computed_attributes.length

  ext_project = client.create_project_from_blueprint(project.blueprint(include_ca: false), auth_token: <TOKEN>, environment: 'TESTING')
  puts "Created ext project: #{ext_project.pid}"
  ext_ca = ext_project.attributes.find { |a| a.title == 'My computed attribute' }
  fail "fould CA in ext project" if ext_ca

  project.partial_md_export(metric.uri, project: ext_project)

  ext_project.update_from_blueprint(project.blueprint)
  ext_ca = ext_project.attributes.find { |a| a.title == 'My computed attribute' }
  fail "ext ca is nil" unless ext_ca
  fail "not a CA" unless ext_ca.computed_attribute?
  puts ext_project.computed_attributes.length
ensure
  project && project.delete
  ext_project && ext_project.delete
  client && client.disconnect
end