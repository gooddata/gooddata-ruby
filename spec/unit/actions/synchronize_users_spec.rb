require 'active_support/core_ext/hash'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::SynchronizeUsers do
  let(:client) { double('client') }
  let(:user) { double('user') }
  let(:data_source) { double('user') }
  let(:domain) { double('domain') }
  let(:project) { double('project') }
  let(:organization) { double('organization') }

  before do
    allow(client).to receive(:projects).and_return(project)
    allow(client).to receive(:user).and_return(user)
    allow(client).to receive(:domain).and_return(domain)
    allow(domain).to receive(:clients).and_return(organization)
    allow(organization).to receive(:project_uri)
    allow(project).to receive(:import_users).and_return([{}])
    allow(project).to receive(:metadata).and_return({})
    allow(project).to receive(:uri)
    allow(project).to receive(:pid).and_return('123456789')
    allow(data_source).to receive(:realize)
    allow(user).to receive(:login).and_return('my_login')
    allow(GoodData::Helpers::DataSource).to receive(:new)
      .and_return(data_source)
  end

  context 'when multiple_projects_column not specified' do
    context 'when mode requires client_id' do
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: 'foo',
          domain: 'bar',
          sync_mode: 'sync_one_project_based_on_custom_id'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(File).to receive(:open).and_return("client_id\nclient123")
      end

      it 'uses client_id column' do
        expect(domain).to receive(:clients).with('client123')
        subject.class.call(params)
      end
    end

    context 'when mode requires client_id' do
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: 'foo',
          domain: 'bar',
          sync_mode: 'sync_one_project_based_on_pid'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(File).to receive(:open).and_return("project_id\n123456789")
      end

      it 'uses project_id column' do
        expect(project).to receive(:import_users) do |filtered_users|
          filtered_users.each do |u|
            expect(u[:pid]).to eq '123456789'
          end
          []
        end
        subject.class.call(params)
      end
    end
  end
end
