describe GoodData::MandatoryUserFilter do
  before :all do
    @client = ConnectionHelper.create_default_connection
    @project, * = ProjectHelper.load_full_project_implementation @client
    @domain = @client.domain(ConnectionHelper::DEFAULT_DOMAIN)
  end

  after :all do
    @project.delete if @project
  end

  describe 'when several users are sharing a MUF' do
    before :all do
      label = @project.labels.to_a.first
      value = label.values.to_a.first

      helper = AppstoreProjectHelper.new(@project, client: @client)
      usr = helper.ensure_user('tttt@tttt.est', @domain)

      other_usr = @domain.find_user_by_login 'rubydev+admin@gooddata.com'

      filters = [[other_usr.email, label.uri, value[:value]]]
      @project.add_data_permissions filters

      muf = GoodData::MandatoryUserFilter.all(client: @client, project: @project).to_a.first
      # TODO: replace this when gooddata-ruby supports MUFs shared between users
      [usr, other_usr].map(&:uri).each do |u|
        payload = {
          'userFilters' => {
            'items' => [
              {
                'user' => u,
                'userFilters' => [muf.uri]
              }
            ]
          }
        }
        @client.post("/gdc/md/#{@project.pid}/userfilters", payload)
      end
    end

    it 'can fetch the related uris' do
      mufs = GoodData::MandatoryUserFilter.all(client: @client, project: @project).to_a
      expect(mufs.first.related_uri.count).to eq 2
    end

    it 'can fetch the related objects' do
      mufs = GoodData::MandatoryUserFilter.all(client: @client, project: @project).to_a
      expect(mufs.first.related.first).to be_a GoodData::Profile
      expect(mufs.first.related.count).to eq 2
    end
  end
end
