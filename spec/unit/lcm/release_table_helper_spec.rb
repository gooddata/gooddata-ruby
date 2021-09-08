describe GoodData::LCM2::Helpers do
  let(:segment_id) { 'premium' }

  describe '.latest_master_project_from_ads' do
    let(:release_table_name) { 'release_table' }
    let(:ads_client) { double('GoodData::Datawarehouse') }

    subject { GoodData::LCM2::Helpers.latest_master_project_from_ads(release_table_name, ads_client, segment_id) }

    before do
      allow(ads_client).to receive(:execute_select) { select_result }
    end

    context 'when release table is empty' do
      let(:select_result) { [] }
      it 'returns nil' do
        expect(subject).to be(nil)
      end
    end

    context 'when release table contains multiple rows' do
      let(:latest_master) do
        { master_project_id: 'baz', version: 3, segment_id: 'premium' }
      end

      let(:select_result) do
        [{ master_project_id: 'foo', version: 1, segment_id: 'premium' },
         { master_project_id: 'bar', version: 2, segment_id: 'premium' },
         latest_master]
      end

      it 'returns latest master' do
        expect(subject).to be(latest_master)
      end
    end
  end

  describe '.master_project_list_from_ads' do
    let(:release_table_name) { 'release_table' }
    let(:ads_client) { double('GoodData::Datawarehouse') }

    subject { GoodData::LCM2::Helpers.get_master_project_list_from_ads(release_table_name, ads_client, segment_id) }

    before do
      allow(ads_client).to receive(:execute_select) { select_result }
    end

    context 'when release table is empty' do
      let(:select_result) { [] }
      it 'returns nil' do
        expect(subject).to eq([])
      end
    end

    context 'when release table contains multiple rows' do
      let(:select_result) do
        [
         { master_project_id: 'foo', version: 113, segment_id: 'premium' },
         { master_project_id: 'bar', version: 9, segment_id: 'premium' },
         { master_project_id: 'baz', version: 12, segment_id: 'premium' }
        ]
      end

      let(:result) do
        [
            { master_project_id: 'bar', version: 9, segment_id: 'premium' },
            { master_project_id: 'baz', version: 12, segment_id: 'premium' },
            { master_project_id: 'foo', version: 113, segment_id: 'premium' }
        ]
      end

      it 'returns master project list' do
        expect(subject).to eq(result)
      end
    end
  end

  context 'when working with a file' do
    let(:domain_id) { 'mydomain' }
    let(:data_prod_id) { 'myprod' }
    let(:first_segment) do
      [
        { master_project_id: 'asdf12', version: 1 },
        { master_project_id: 'ghjk34', version: 2 }
      ]
    end
    let(:second_segment) do
      [{ master_project_id: 'klmn56', version: 1 }]
    end

    before do
      ENV['RELEASE_TABLE_NFS_DIRECTORY'] = 'release-tables'
      GoodData.gd_logger = Logger.new(STDOUT)
      allow(GoodData::Helpers::Csv).to receive(:read_as_hash).with(GoodData::LCM2::Helpers.path_to_release_table_file(domain_id, data_prod_id, 'first_segment')) { first_segment }
      allow(GoodData::Helpers::Csv).to receive(:read_as_hash).with(GoodData::LCM2::Helpers.path_to_release_table_file(domain_id, data_prod_id, 'second_segment')) { second_segment }
    end

    describe '.latest_master_project_from_nfs' do
      it 'returns latest master' do
        expect(GoodData::LCM2::Helpers.latest_master_project_from_nfs(domain_id, data_prod_id, 'first_segment')).to eq(master_project_id: 'ghjk34', version: 2)
      end
    end

    describe '.update_latest_master_to_nfs' do
      let(:new_data) do
        { master_project_id: 'opqr78', version: 2 }
      end
      let(:segment) { 'second_segment' }

      it 'ammends the master record to the file' do
        GoodData::LCM2::Helpers.update_latest_master_to_nfs(domain_id, data_prod_id, segment, new_data[:master_project_id], new_data[:version])
        data = GoodData::LCM2::Helpers.latest_master_project_from_nfs(domain_id, data_prod_id, segment)
        expect(data).to eq(new_data)
      end
    end

    describe '.path_to_release_table_file' do
      let(:domain_id) { 'mydomain' }
      let(:segment_id) { 'mysegment' }

      it 'returns a valid filepath' do
        expect(GoodData::LCM2::Helpers.path_to_release_table_file(domain_id, data_prod_id, segment_id)).to eq 'release-tables/mydomain/myprod-mysegment.csv'
      end
    end

    describe '.master_project_list_from_nfs' do
      let(:result) do
        [
            { master_project_id: 'asdf12', version: 1 },
            { master_project_id: 'ghjk34', version: 2 }
        ]
      end

      it 'returns master project list' do
        expect(GoodData::LCM2::Helpers.get_master_project_list_from_nfs(domain_id, data_prod_id, 'first_segment')).to eq(result)
      end
    end
  end

  context 'when update master project to nfs' do
    let(:domain_id) { 'mydomain' }
    let(:data_prod_id) { 'myprod' }

    let(:one_master_project_data) do
      [
          { master_project_id: 'opi15', version: 3 }
      ]
    end
    let(:segment_id) { 'third_segment' }

    let(:many_master_project_data) do
      [
          { master_project_id: 'agh1', version: 2 },
          { master_project_id: 'jhq3', version: 3 }
      ]
    end

    before do
      ENV['RELEASE_TABLE_NFS_DIRECTORY'] = 'release-tables'
      GoodData.gd_logger = Logger.new(STDOUT)
    end

    after do
      file_path = GoodData::LCM2::Helpers.path_to_release_table_file(domain_id, data_prod_id, segment_id)
      File.delete(file_path) if File.exist? file_path
    end

    describe '.update master project to nfs' do
      it 'update one master project to the file' do
        GoodData::LCM2::Helpers.update_master_project_to_nfs(domain_id, data_prod_id, segment_id, one_master_project_data)
        data = GoodData::LCM2::Helpers.get_master_project_list_from_nfs(domain_id, data_prod_id, segment_id)
        expect(data).to eq(one_master_project_data)
      end

      it 'update many master project to the file' do
        GoodData::LCM2::Helpers.update_master_project_to_nfs(domain_id, data_prod_id, segment_id, many_master_project_data)
        data = GoodData::LCM2::Helpers.get_master_project_list_from_nfs(domain_id, data_prod_id, segment_id)
        expect(data).to eq(many_master_project_data)
      end
    end
  end
end
