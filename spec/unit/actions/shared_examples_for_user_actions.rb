shared_examples 'a user action reading client_id' do
  before do
    allow(File).to receive(:open).and_return("client_id\n#{client_id}")
  end

  it 'uses cache for client_ids' do
    expect(domain).to receive(:clients).with(:all, nil)
    subject.class.call(params)
  end
end

shared_examples 'a user action filtering segments' do
  let(:organization_not_in_segment) { double('organization') }
  let(:project_not_in_segment) { double('project') }

  before do
    allow(organization_not_in_segment).to receive(:segment_uri).and_return('another-segment-uri')
    allow(organization_not_in_segment).to receive(:project).and_return(project_not_in_segment)
  end

  it 'does operation on project only from clients in segments in segments filter' do
    expect(project).to receive(message_for_project)
    expect(project_not_in_segment).not_to receive(message_for_project)
    subject.class.call(params)
  end
end

shared_examples 'when using unsuported sync_mode' do
  before do
    allow(project).to receive(:metadata).and_return(
      'GOODOT_CUSTOM_PROJECT_ID' => 'project-123'
    )
    allow(project).to receive(:uri).and_return('project-uri')
    allow(data_source).to receive(:realize).and_return('filepath')
    allow(File).to receive(:open).and_return("client_id\n123456789")
    allow(project).to receive(:add_data_permissions)
    allow(domain).to receive(:clients).and_return([])
  end

  it 'fails' do
    expect { subject.class.call(params) }.to raise_error(/sync_mode/)
  end
end
