# encoding: UTF-8
#
# Copyright (c) 2010-2017 GoodData Corporation. All rights reserved.
# This source code is licensed under the BSD-style license found in the
# LICENSE file in the root directory of this source tree.

require 'gooddata/helpers/csv_helper'
require 'csv'

describe GoodData::Helpers::Csv do
  describe '#read' do
    it 'Reads data from CSV file' do
      GoodData::Helpers::Csv.read(:path => CsvHelper::CSV_PATH_IMPORT)
    end
  end

  describe '#write' do
    it 'Writes data to CSV' do
      data = []
      GoodData::Helpers::Csv.write(:path => CsvHelper::CSV_PATH_EXPORT, :data => data)
    end
  end

  context 'when a CSV file exists' do
    before do
      @data = [
        { segment_id: 'first_segment', master_project_id: 'asdf12', version: 1 },
        { segment_id: 'first_segment', master_project_id: 'ghjk34', version: 2 },
        { segment_id: 'second_segment', master_project_id: 'klmn56', version: 1 }
      ]
      @tempfile = Tempfile.new('lcm_data_helper_spec')
      CSV.open(@tempfile, 'w', write_headers: true, headers: @data.first.keys) do |csv|
        @data.each { |hash| csv << hash }
      end
    end

    after do
      File.delete(@tempfile)
    end

    describe '#read_csv_as_hash' do
      it 'reads data from a file' do
        data = subject.class.read_as_hash(@tempfile)
        expect(data).to eq(@data)
      end
    end

    describe '#ammend_line_to_csv' do
      it 'writes data to a file' do
        new_line = { segment_id: 'second_segment', master_project_id: 'zxcv78', version: 2 }
        subject.class.ammend_line(@tempfile.path, new_line)
        data = subject.class.read_as_hash(@tempfile)
        expect(data).to eq(@data << new_line)
      end

      it 'does not rely on the order of the hash keys' do
        new_line = { master_project_id: 'zxcv78', version: 2, segment_id: 'second_segment' }
        subject.class.ammend_line(@tempfile.path, new_line)
        data = subject.class.read_as_hash(@tempfile)
        expect(data). to eq(@data << new_line)
      end
    end
  end
end
