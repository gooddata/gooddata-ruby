shared_examples 'a provisioning or rollout brick' do
  it 'sets dynamic parameters' do
    projects.each do |target_project|
      target_schedules = target_project.schedules
      client_id = @workspaces.find { |w| w[:title] == target_project.title }[:client_id]

      target_schedules.each do |target_schedule|
        all_dynamic_param = target_schedule.params[Support::ALL_DYNAMIC_PARAMS_KEY]
        expect(all_dynamic_param).to eq(Support::ALL_DYNAMIC_PARAMS_VALUE)

        dynamic_param = target_schedule.params[Support::DYNAMIC_PARAMS_KEY]
        if target_schedule.name == Support::RUBY_HELLO_WORLD_SCHEDULE_NAME
          expect(dynamic_param).to eq(client_id)
        else
          expect(dynamic_param).to be_nil
        end
      end
    end
  end
end
