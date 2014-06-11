# encoding: UTF-8

require 'gooddata/helpers/csv_helper'

describe GoodData::Helpers::Csv do
  describe '#read' do
    it 'Reads data from CSV file' do
      data = GoodData::Helpers::Csv.read(:path => CsvHelper::CSV_PATH_IMPORT)
    end
  end

  describe '#write' do
    it 'Writes data to CSV' do
      data = []
      GoodData::Helpers::Csv.write(:path => CsvHelper::CSV_PATH_EXPORT, :data => data)
    end
  end
end