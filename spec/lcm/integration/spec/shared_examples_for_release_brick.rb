shared_examples 'a release brick' do
  it 'does not transfer ADD components' do
    dev_add_component = original_project.processes.find { |process| process.name == ADD_V2_COMPONENT_NAME }
    expect(dev_add_component).to be
    projects.map do |p|
      add_component = p.processes.find { |process| process.name == ADD_V2_COMPONENT_NAME }
      expect(add_component).to be_nil
    end
  end
end
