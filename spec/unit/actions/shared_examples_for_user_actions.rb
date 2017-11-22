shared_examples 'a user action' do
  before do
    allow(File).to receive(:open).and_return("client_id\n#{client_id}")
  end

  it 'uses client_id column' do
    expect(domain).to receive(:clients).with(client_id, nil)
    subject.class.call(params)
  end
end
