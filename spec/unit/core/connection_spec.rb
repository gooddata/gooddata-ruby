describe GoodData::Rest::Connection do
  subject { GoodData::Rest::Connection.new({}) }
  let(:exception) { StandardError }
  let(:request_error) { double('request_error') }
  let(:request_id) { 'random_request_id_string' }

  before do
    allow(exception).to receive(:response) { request_error }
    allow(exception).to receive(:message) { exception.to_s }
    allow(request_error).to receive(:body) {
      {
        error:
          {
            parameters: ['project', 'STRUCTURE INVALID'],
            requestId: request_id,
            component: 'Apache::REST',
            errorClass: 'GDC::Exception::User',
            message: "Checking '%s', result %s"
          }
      }.to_json
    }
  end
  it 'enriches the exception' do
    expect(exception).to receive(:message=).with("StandardError: Checking 'project', result STRUCTURE INVALID request_id: random_request_id_string")
    subject.enrich_error_message(exception)
  end
end
