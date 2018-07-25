describe GoodData::LCM2::Helpers do
  describe '.latest_master_project' do
    let(:release_table_name) { 'release_table' }
    let(:ads_client) { double('GoodData::Datawarehouse') }
    let(:segment_id) { 'premium' }

    subject { GoodData::LCM2::Helpers.latest_master_project(release_table_name, ads_client, segment_id) }

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
end
