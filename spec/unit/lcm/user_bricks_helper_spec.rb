describe GoodData::LCM2::UserBricksHelper do
  subject { GoodData::LCM2::UserBricksHelper.resolve_client_id(domain, project, data_product) }
  let(:domain) { double('domain') }
  let(:project) { double('project') }
  let(:data_product) { double('data_product') }
  let(:project_uri) { '/gdc/projects/fooooo' }
  let(:clients) { [client] }
  let(:client) { double('client') }
  let(:client_id) { 'bar' }
  let(:project_id) { 'baz' }

  before do
    allow(project).to receive(:metadata).and_return(metadata)
    allow(project).to receive(:uri).and_return(project_uri)
    allow(domain).to receive(:clients).and_return(clients)
    allow(client).to receive(:project_uri).and_return(project_uri)
    allow(client).to receive(:id).and_return(client_id)
    allow(project).to receive(:id).and_return(project_id)
    allow(project).to receive(:pid).and_return(project_id)
  end
  shared_examples_for 'a client id resolver' do
    context 'when client matches specified project url' do
      it 'returns client id' do
        expect(subject).to eq(client_id)
      end
    end
  end

  describe '.resolve_client_id' do
    context 'when GOODOT_CUSTOM_PROJECT_ID specified' do
      let(:metadata) { { 'GOODOT_CUSTOM_PROJECT_ID' => client_id } }
      it_behaves_like 'a client id resolver'

      context 'when goodot id does not match client id' do
        before { allow(client).to receive(:id).and_return('different_id') }
        it 'raises an error' do
          expect { subject }.to raise_error(/doesn't match client id/)
        end
      end
    end

    context 'when GOODOT_CUSTOM_PROJECT_ID not specified' do
      let(:metadata) { { 'GOODOT_CUSTOM_PROJECT_ID' => nil } }
      it_behaves_like 'a client id resolver'

      context 'when no client matches project url' do
        before do
          allow(client).to receive(:project_uri).and_return('different/uri')
        end

        it 'raises an error' do
          expected = /does not contain key GOODOT_CUSTOM_PROJECT_ID/
          expect { subject }.to raise_error(expected)
        end
      end
    end
  end

  describe '.non_working_clients' do
    let(:metadata) { { 'PROJECT_ID' => 'testing' } }

    it 'returns correct non working clients' do
      working_client_01_id = 'c01'
      working_client_02_id = 'c02'
      working_client_03_id = 'c03'
      non_working_client_01_id = 'non_working_c01'
      non_working_client_02_id = 'non_working_c02'

      domain_clients = []
      domain_clients << GoodData::Client.new(data: { 'id' => working_client_01_id })
      domain_clients << GoodData::Client.new(data: { 'id' => working_client_02_id })
      domain_clients << GoodData::Client.new(data: { 'id' => working_client_03_id })
      domain_clients << GoodData::Client.new(data: { 'id' => non_working_client_01_id })
      domain_clients << GoodData::Client.new(data: { 'id' => non_working_client_02_id })

      working_client_ids = [working_client_01_id, working_client_02_id, working_client_03_id]
      non_working_client_ids = []
      expected_non_working_client_ids = [non_working_client_01_id, non_working_client_02_id]

      non_working_clients = GoodData::LCM2::UserBricksHelper.non_working_clients(domain_clients, working_client_ids)
      non_working_clients.each { |c| non_working_client_ids << c.client_id}

      expect(non_working_client_ids).to eq expected_non_working_client_ids
    end
  end
end
