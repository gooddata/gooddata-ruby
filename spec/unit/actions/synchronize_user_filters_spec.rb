require 'active_support/core_ext/hash'
require 'gooddata/lcm/lcm2'

describe GoodData::LCM2::SynchronizeUserFilters do
  let(:client) { double('client') }
  let(:user) { double('user') }
  let(:data_source) { double('user') }
  let(:domain) { double('domain') }
  let(:project) { double('project') }
  let(:organization) { double('organization') }
  let(:logger) { double(Logger) }

  before do
    allow(client).to receive(:projects).and_return(project)
    allow(client).to receive(:domain).and_return(domain)
    allow(organization).to receive(:project_uri)
    allow(project).to receive(:add_data_permissions).and_return([{}])
    allow(project).to receive(:pid).and_return('123456789')
    allow(user).to receive(:login).and_return('my_login')
    allow(GoodData::Helpers::DataSource).to receive(:new).and_return(data_source)
  end

  context 'when multiple_projects_column not specified' do
    before do
      allow(project).to receive(:metadata).and_return({})
      allow(project).to receive(:uri)
      allow(domain).to receive(:clients).and_return(organization)
      allow(data_source).to receive(:realize)
      allow(organization).to receive(:find)
    end
    context 'when mode requires client_id' do
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: 'foo',
          domain: 'bar',
          filters_config: { labels: [] },
          sync_mode: 'sync_one_project_based_on_pid'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(File).to receive(:open).and_return("project_id\n123456789")
      end

      it 'uses project_id column' do
        expect(GoodData::UserFilterBuilder).to receive(:get_filters) do |filters, _|
          CSV.foreach(filters, headers: true, return_headers: false) do |row|
            expect(row['project_id']).to eq '123456789'
          end
          []
        end
        subject.class.call(params)
      end
    end
  end

  context 'when using sync_one_project_based_on_custom_id mode with multiple_projects_column' do
    let(:params) do
      params = {
        GDC_GD_CLIENT: client,
        input_source: 'foo',
        domain: 'bar',
        filters_config: { labels: [] },
        multiple_projects_column: 'id_column',
        sync_mode: 'sync_one_project_based_on_custom_id',
        gdc_logger: logger
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    let(:CSV) { double('CSV') }

    before do
      allow(project).to receive(:metadata).and_return(
        'GOODOT_CUSTOM_PROJECT_ID' => 'project-123'
      )
      allow(project).to receive(:uri).and_return('project-uri')
      allow(project).to receive(:add_data_permissions)
      allow(domain).to receive(:clients).and_return([])
      allow(data_source).to receive(:realize).and_return('filepath')
    end

    context 'when params do not match client data in domain' do
      before do
        allow(project).to receive(:metadata).and_return({})
        allow(project).to receive(:uri).and_return('project-uri')
        allow(domain).to receive(:clients).and_return([])
      end

      it 'fails when unable to get filter value for selecting filters' do
        expect { subject.class.call(params) }.to raise_exception(/does not contain key GOODOT_CUSTOM_PROJECT_ID/)
      end
    end

    context 'when params match a client in the domain' do
      it 'adds filters matching the client' do
        expect(File).to receive(:open)
        csv_data = [
          {
            'id_column' => 'project-123'
          },
          {
            'id_column' => 'another-project'
          }
        ]
        expect(CSV).to receive(:foreach).and_yield(csv_data[0]).and_yield(csv_data[1])
        expect(GoodData::UserFilterBuilder).to receive(:get_filters) do |filters, _|
          filters.each do |filter|
            expect(filter['id_column']).to eq 'project-123'
          end
        end
        subject.class.call(params)
      end
    end

    context 'when the input set does not contain data for the current project' do
      it 'does not fail and logs a warning' do
        expect(File).to receive(:open)
        expect(CSV).to receive(:foreach).and_yield({})
        expect(project).to receive(:add_data_permissions)
        expect(logger).to receive(:warn)
        expect { subject.class.call(params) }.to_not raise_error
      end
    end
  end
end
