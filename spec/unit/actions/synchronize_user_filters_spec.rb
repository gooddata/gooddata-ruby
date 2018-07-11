require 'active_support/core_ext/hash'
require 'gooddata/lcm/lcm2'

require_relative 'shared_examples_for_user_actions'

shared_context 'using mode with custom_id' do
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
end

describe GoodData::LCM2::SynchronizeUserFilters do
  let(:client) { double('client') }
  let(:user) { double('user') }
  let(:data_source) { double('user') }
  let(:domain) { double('domain') }
  let(:project) { double('project') }
  let(:organization) { double('organization') }
  let(:logger) { double(Logger) }
  let(:data_product) { double('data product') }

  before do
    allow(client).to receive(:class).and_return(GoodData::Rest::Client)
    allow(data_product).to receive(:class).and_return GoodData::DataProduct
    allow(logger).to receive(:class).and_return Logger

    allow(client).to receive(:projects).and_return(project)
    allow(client).to receive(:domain).and_return(domain)
    allow(organization).to receive(:project_uri)
    allow(project).to receive(:add_data_permissions).and_return(results: [])
    allow(project).to receive(:pid).and_return('123456789')
    allow(user).to receive(:login).and_return('my_login')
    allow(GoodData::Helpers::DataSource).to receive(:new).and_return(data_source)
    allow(logger).to receive(:warn)
  end

  context 'when multiple_projects_column not specified' do
    before do
      allow(project).to receive(:metadata).and_return({})
      allow(project).to receive(:uri)
      allow(data_source).to receive(:realize)
      allow(organization).to receive(:id).and_return('client123')
      allow(organization).to receive(:project).and_return(project)
    end
    context 'when mode requires client_id' do
      before do
        allow(domain).to receive(:clients).and_return(organization)
      end
      let(:params_stub) do
        {
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          filters_config: { labels: [] },
          gdc_logger: logger,
          data_product: data_product
        }
      end

      it_behaves_like 'a user action reading client_id' do
        let(:params) { GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: 'sync_multiple_projects_based_on_custom_id')) }
        let(:client_id) { '123456789' }
      end

      context 'when using multiple_projects modes' do
        let(:message_for_project) { :add_data_permissions }
        before do
          allow(domain).to receive(:clients).with(:all, data_product).and_return([organization])
          allow(domain).to receive(:clients).with(123_456_789, data_product).and_return(organization)
          allow(organization).to receive(:project).and_return(project)
          allow(organization).to receive(:client_id).and_return(123_456_789)
          allow(File).to receive(:open).and_return("client_id\n123456789")
          allow(project).to receive(:deleted?).and_return false
        end

        context 'sync_multiple_projects_based_on_custom_id mode' do
          let(:params) { GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: 'sync_multiple_projects_based_on_custom_id')) }
          before do
            allow(File).to receive(:open).and_return("client_id\n123456789")
            allow(domain).to receive(:clients).with(:all, nil).and_return([organization, organization_not_in_segment])
            allow(domain).to receive(:clients).with('123456789', nil).and_return(organization)
          end

          it_behaves_like 'a user action filtering segments'
        end

        context 'sync_multiple_projects_based_on_pid mode' do
          let(:params) { GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: 'sync_multiple_projects_based_on_pid')) }
          before do
            allow(File).to receive(:open).and_return("project_id\n123456789")
            allow(domain).to receive(:projects).with(:all, nil).and_return([organization, organization_not_in_segment])
            allow(domain).to receive(:projects).with('123456789', nil).and_return(organization)
          end

          it_behaves_like 'a user action filtering segments'
        end


        context 'sync_domain_client_workspaces mode' do
          let(:params) { GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: 'sync_domain_client_workspaces')) }
          before do
            allow(File).to receive(:open).and_return("client_id\n123456789")
            allow(domain).to receive(:clients).with(:all, nil).and_return([organization, organization_not_in_segment])
            allow(domain).to receive(:clients).with('123456789', nil).and_return(organization)
          end

          it_behaves_like 'a user action filtering segments'
        end

        context 'when dry_run param is true' do
          let(:params) { GoodData::LCM2.convert_to_smart_hash(params_stub.merge(sync_mode: 'sync_domain_client_workspaces', dry_run: 'true')) }

          it 'sets the dry_run option' do
            expect(project).to receive(:add_data_permissions).twice
              .with(instance_of(Array), hash_including(dry_run: true))
              .and_return(results: [])
            GoodData::LCM2.run_action(subject.class, params)
          end
        end
      end
    end
  end

  context 'when using sync_one_project_based_on_custom_id mode with multiple_projects_column' do
    include_context 'using mode with custom_id'
    let(:params) do
      params = {
        GDC_GD_CLIENT: client,
        input_source: {},
        domain: 'bar',
        filters_config: { labels: [] },
        multiple_projects_column: 'id_column',
        sync_mode: 'sync_one_project_based_on_custom_id',
        gdc_logger: logger,
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    context 'when params do not match client data in domain' do
      before do
        allow(project).to receive(:metadata).and_return({})
        allow(project).to receive(:uri).and_return('project-uri')
        allow(domain).to receive(:clients).and_return([])
      end

      it 'fails when unable to get filter value for selecting filters' do
        expect { GoodData::LCM2.run_action(subject.class, params) }.to raise_exception(/does not contain key GOODOT_CUSTOM_PROJECT_ID/)
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
        GoodData::LCM2.run_action(subject.class, params)
      end
    end

    context 'when the input set does not contain data for the current project' do
      it 'does not fail and logs a warning' do
        expect(File).to receive(:open)
        expect(CSV).to receive(:foreach).and_yield({})
        expect(project).to receive(:add_data_permissions)
        expect(logger).to receive(:warn)
        expect { GoodData::LCM2.run_action(subject.class, params) }.to_not raise_error
      end
    end
  end

  context 'when using sync_multiple_projects_based_on_custom_id mode' do
    include_context 'using mode with custom_id'
    let(:params) do
      params = {
        input_source: {},
        domain: 'bar',
        multiple_projects_column: 'id_column',
        sync_mode: 'sync_multiple_projects_based_on_custom_id',
        gdc_logger: logger,
        GDC_GD_CLIENT: client,
        filters_config: { labels: [] },
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end
    it 'fails if the MUF set is empty' do
      expect(File).to receive(:open)
      expect(CSV).to receive(:foreach)
      expect { GoodData::LCM2.run_action(subject.class, params) }.to raise_error(/The filter set can not be empty/)
    end
  end
  context 'when using unsuported sync_mode' do
    let(:params) do
      params = {
        filters_config: { labels: [] },
        GDC_GD_CLIENT: client,
        input_source: {},
        domain: 'bar',
        multiple_projects_column: 'id_column',
        sync_mode: 'unsuported_sync_mode', # sync_one_project_based_on_custom_id
        gdc_logger: logger,
        data_product: data_product
      }
      GoodData::LCM2.convert_to_smart_hash(params)
    end

    it_should_behave_like 'when using unsuported sync_mode'
  end
end
