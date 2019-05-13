describe GoodData::Rest::Connection do
  subject { GoodData::Rest::Connection.new({}) }

  context 'when an error is thrown' do
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
      allow(request_error).to receive(:headers) { { x_gdc_request: request_id } }
    end
    it 'enriches the exception' do
      expect(exception).to receive(:message=).with("StandardError: Checking 'project', result STRUCTURE INVALID request_id: random_request_id_string")
      subject.enrich_error_message(exception)
    end
  end

  context 'when connecting to a server' do
    it 'omits the trailing slash' do
      res = subject.send(:fix_server_url, 'https://trailing-slash.com/')
      expect(res).to eq('https://trailing-slash.com')
    end

    it 'prefixes the string with https' do
      res = subject.send(:fix_server_url, 'no-protocol-specified.com')
      expect(res).to eq('https://no-protocol-specified.com')
    end

    it 'fixes http to https with a warning' do
      expect(GoodData.logger).to receive(:warn).with('You specified the HTTP protocol in your server string. It has been autofixed to HTTPS.')
      res = subject.send(:fix_server_url, 'http://this-is-dangerous.com')
      expect(res).to eq('https://this-is-dangerous.com')
    end
  end
end
