shared_examples 'a provisioning/rollout brick' do
  it 'sets dynamic parameters' do
    projects.each do |target_project|
      target_schedules = target_project.schedules
      target_schedules.each do |target_schedule|
        require 'pry';binding.pry
        all_dynamic_param = target_schedule.params[Support::ALL_DYNAMIC_PARAMS_KEY] == Support::ALL_DYNAMIC_PARAMS_VALUE
        expect(all_dynamic_param).to be(true)
        client_id = @workspaces.find { |w| w[:title] == target_project.title }[:client_id]
        dynamic_param = target_schedule.params[Support::DYNAMIC_PARAMS_KEY]
        expect(dynamic_param).to eq(client_id)
      end
    end
  end
end
