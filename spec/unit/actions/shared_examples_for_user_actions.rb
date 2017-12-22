shared_examples 'a user action reading client_id' do
  before do
    allow(File).to receive(:open).and_return("client_id\n#{client_id}")
  end

  it 'uses client_id column' do
    expect(domain).to receive(:clients).with(client_id, nil)
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
