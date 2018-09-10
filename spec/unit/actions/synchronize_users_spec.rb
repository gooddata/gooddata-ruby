require 'active_support/core_ext/hash'
require 'gooddata/lcm/lcm2'
require_relative 'shared_examples_for_user_actions'

shared_examples_for 'a user synchronizer' do
  it 'does not fail and logs a warning' do
    expect(logger).to receive(:warn).with(/not match any client ids/)
    expect { subject.class.call(params) }.to_not raise_error
  end
end

describe GoodData::LCM2::SynchronizeUsers do
  let(:client) { double('client') }
  let(:user) { double('user') }
  let(:data_source) { double('user') }
  let(:domain) { double('domain') }
  let(:project) { double('project') }
  let(:organization) { double('organization') }
  let(:logger) { double('logger') }
  let(:project_uri) { '/gdc/projects/123abc' }
  let(:data_product) { double('data product') }

  before do
    allow(client).to receive(:class).and_return(GoodData::Rest::Client)
    allow(data_product).to receive(:class).and_return GoodData::DataProduct
    allow(logger).to receive(:class).and_return Logger

    allow(client).to receive(:projects).and_return(project)
    allow(client).to receive(:user).and_return(user)
    allow(client).to receive(:domain).and_return(domain)
    allow(organization).to receive(:project_uri).and_return(project_uri)
    allow(project).to receive(:import_users).and_return([{}])
    allow(project).to receive(:metadata).and_return({})
    allow(project).to receive(:uri).and_return(project_uri)
    allow(project).to receive(:pid).and_return('123456789')
    allow(data_source).to receive(:realize)
    allow(user).to receive(:login).and_return('my_login')
    allow(GoodData::Helpers::DataSource).to receive(:new)
      .and_return(data_source)
    allow(logger).to receive(:debug)
  end

  context 'when multiple_projects_column not specified' do
    context 'when mode is sync_one_project_based_on_custom_id' do
      let(:client_id) { '123456789' }

      before do
        allow(domain).to receive(:clients).and_return([organization])
        allow(organization).to receive(:id).and_return(client_id)
      end

      let(:params) do
        params = {
          sync_mode: 'sync_one_project_based_on_custom_id',
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger,
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      context 'when the input set is empty' do
        before do
          allow(File).to receive(:open).and_return("")
        end

        it_behaves_like 'a user synchronizer'
      end

      context 'when the input set does not contain data for the current project' do
        before do
          allow(File).to receive(:open).and_return("client_id\ndifferent_from_123")
        end

        it_behaves_like 'a user synchronizer'
      end
    end

    context 'when mode requires client_id' do
      let(:params) do
        params = {
          sync_mode: 'sync_one_project_based_on_pid',
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(File).to receive(:open).and_return("project_id\n123456789")
        allow(domain).to receive(:clients).and_return(organization)
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

    context 'when using multiple_projects modes' do
      let(:segment) { double('segment') }
      let(:segment_uri) { 'segment_uri' }
      let(:message_for_project) { :import_users }
      let(:params_stub) do
        {
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger,
          segments: [segment]
        }
      end

      before do
        allow(segment).to receive(:uri).and_return(segment_uri)
        allow(segment).to receive(:segment_id).and_return('123')
        allow(segment).to receive(:development_pid).and_return('456')
        allow(segment).to receive(:driver).and_return('vertica')
        allow(segment).to receive(:production_tags).and_return([])
        allow(segment).to receive(:master_name).and_return('charles')
        allow(organization).to receive(:segment_uri).and_return(segment_uri)
        allow(organization).to receive(:project).and_return(project)
        allow(organization).to receive(:client_id).and_return('123456789')
        allow(project).to receive(:deleted?).and_return(false)
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


    end

    context 'when using mode' do
      let(:segment) { double('segment') }
      let(:segment_uri) { 'segment_uri' }
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger,
          sync_mode: 'sync_domain_client_workspaces',
          segments: [segment]
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(File).to receive(:open).and_return("client_id\n123456789")
        allow(domain).to receive(:clients).with(:all, nil).and_return([organization, organization_not_in_segment])
        allow(domain).to receive(:clients).with('123456789', nil).and_return(organization)

        allow(segment).to receive(:uri).and_return(segment_uri)
        allow(segment).to receive(:segment_id).and_return('123')
        allow(segment).to receive(:development_pid).and_return('456')
        allow(segment).to receive(:driver).and_return('vertica')
        allow(segment).to receive(:production_tags).and_return([])
        allow(segment).to receive(:master_name).and_return('charles')

        allow(organization).to receive(:segment_uri).and_return(segment_uri)
        allow(organization).to receive(:project).and_return(project)
        allow(organization).to receive(:client_id).and_return('123456789')
        allow(project).to receive(:deleted?).and_return(false)
      end

      it_behaves_like 'a user action filtering segments' do
        let(:message_for_project) { :import_users }
      end
    end
    context 'when using mistyped mode' do
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger,
          sync_mode: 'unsuported_sync_mode'
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(domain).to receive(:clients).and_return(organization)
      end
      it_should_behave_like 'when using unsuported sync_mode'
    end
    context 'when using no mode' do
      let(:params) do
        params = {
          GDC_GD_CLIENT: client,
          input_source: {},
          domain: 'bar',
          gdc_logger: logger
        }
        GoodData::LCM2.convert_to_smart_hash(params)
      end

      before do
        allow(domain).to receive(:clients).and_return(organization)
      end
      before do
        allow(data_source).to receive(:realize).and_return('filepath')
        allow(File).to receive(:open).and_return("client_id\n123456789")
        allow(project).to receive(:metadata).and_return(
          'GOODOT_CUSTOM_PROJECT_ID' => 'project-123'
        )
        allow(project).to receive(:uri).and_return('project-uri')
        allow(project).to receive(:add_data_permissions)
        allow(domain).to receive(:clients).and_return([])
      end

      it 'fails' do
        expect { subject.class.call(params) }.to raise_error(/sync_mode/)
      end
    end
  end
end
