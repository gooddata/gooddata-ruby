require 'gooddata/cli/cli'

describe GoodData::CLI do
  before do
    allow(GoodData::Helpers::AuthHelper).to receive(:read_credentials) { credentials }
  end

  context 'when verify_ssl is not specified' do
    let(:credentials) { { username: 'john', password: 'secret' } }

    it 'sets verify_ssl to true' do
      expect(GoodData::Command::Api).to receive(:get).with(['/gdc/md'], hash_including(verify_ssl: true))
      GoodData::CLI.main(['api', 'get', '/gdc/md'])
    end
  end
end
