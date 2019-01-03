shared_context 'load tests' do
  after(:all) do
    system('GD_ENV=performance bundle exec ruby bin/test_projects_cleanup.rb -d 0 -f') ||
      fail('Load test clean-up failed.')
  end
end
