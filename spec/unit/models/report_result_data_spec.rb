require 'gooddata/models/report_data_result'

describe GoodData::ReportDataResult do

  before(:each) do
    data = JSON.parse(File.read('./spec/data/reports/report_1.json'))
    @result = GoodData::ReportDataResult.from_xtab(data)
    @result2 = GoodData::ReportDataResult.from_xtab(data)
  end

  it 'should compute columns' do
    expect(@result.to_a).to eq [[nil, "kolin", "praha", "varsava"],
                                [nil, "sum of Age", "sum of Age", "sum of Age"],
                                ["jirka", 25, nil, nil],
                                ["petr", nil, nil, 15],
                                ["tomas", nil, 25, nil]]
  end

  it 'should compute columns' do
    expect(@result.left_headers).to eq [["jirka"],
                                        ["petr"],
                                        ["tomas"]]
  end

  it 'should compute columns' do
    expect(@result.top_headers).to eq [["kolin", "praha", "varsava"],
                                       ["sum of Age", "sum of Age", "sum of Age"]]
  end

  describe '#slice' do
    it 'slice on zeroes should be equal to original' do
      expect(@result.slice(0, 0)).to eq @result
    end

    it 'slice on data should return just data' do
      expect(@result.slice(2, 1).to_a).to eq [[25, nil, nil],
                                              [nil, nil, 15],
                                              [nil, 25, nil]]
    end

    it 'should return data result with correct size' do
      expect(@result.slice(2, 1).size).to eq [3, 3]
    end

    it 'should return data result with correct headers' do
      expect(@result.left_headers).to eq [["jirka"], ["petr"], ["tomas"]]
      expect(@result.top_headers).to eq [["kolin", "praha", "varsava"],
                                         ["sum of Age", "sum of Age", "sum of Age"]]
    end

  end

  describe '#without_left_headers' do
    it 'should return data result without left headers' do
      expect(@result.without_left_headers.to_a).to eq [["kolin", "praha", "varsava"],
                                                       ["sum of Age", "sum of Age", "sum of Age"],
                                                       [25, nil, nil],
                                                       [nil, nil, 15],
                                                       [nil, 25, nil]]
    end

    it 'should return correct size' do
      expect(@result.without_left_headers.size).to eq [5, 3]
    end

    it 'should return correct left headers' do
      expect(@result.without_top_headers.top_headers).to eq nil
    end
  end

  describe '#without_top_headers' do
    it 'should return data result without left headers' do
      expect(@result.without_top_headers.to_a).to eq [["jirka", 25, nil, nil],
                                                      ["petr", nil, nil, 15],
                                                      ["tomas", nil, 25, nil]]
    end

    it 'should return correct size' do
      expect(@result.without_top_headers.size).to eq [3, 4]
    end

    it 'should return correct left headers' do
      expect(@result.without_top_headers.left_headers).to eq [["jirka"],
                                                              ["petr"],
                                                              ["tomas"]]
    end

    it 'should return correct top headers' do
      expect(@result.without_top_headers.top_headers).to eq nil
    end
  end

  it 'should work with left attribute reports' do
    data = JSON.parse(File.read('./spec/data/reports/left_attr_report.json'))
    result = GoodData::ReportDataResult.from_xtab(data)
    expect(result.left_headers).to eq [["jirka"], ["petr"], ["tomas"]]
    expect(result.size).to eq [4, 2]
    expect(result.data_size).to eq [3, 1]
  end

  it 'should work with left attribute reports' do
    data = JSON.parse(File.read('./spec/data/reports/top_attr_report.json'))
    result = GoodData::ReportDataResult.from_xtab(data)
    expect(result.size).to eq [2, 4]
    expect(result.data_size).to eq [1, 3]
    expect(result.left_headers).to eq [["Values"]]
    expect(result.top_headers).to eq [["jirka", "petr", "tomas"]]
  end

  it 'should fail when comparing two different reports' do
    data = JSON.parse(File.read('./spec/data/reports/left_attr_report.json'))
    a = GoodData::ReportDataResult.from_xtab(data)
    data = JSON.parse(File.read('./spec/data/reports/top_attr_report.json'))
    b = GoodData::ReportDataResult.from_xtab(data)
    expect(a == b).to be_falsey
  end

  describe '#size' do
    it 'should compute columns' do
      expect(@result.size).to eq [5, 4]
    end

    it 'should compute columns' do
      expect(@result.size).to eq @result2.size
    end
  end

  describe '#data' do
    it 'should return just data portion' do
      expect(@result.data.is_a?(GoodData::ReportDataResult)).to be_truthy
      expect(@result.data.to_a).to eq [[25, nil, nil],
                                       [nil, nil, 15],
                                       [nil, 25, nil]]
    end
  end

  describe '#[]' do
    it 'should return correct line' do
      expect(@result[2]).to eq ['jirka', 25, nil, nil]
    end
  end

  describe '#column' do
    it 'should return correct line' do
      expect(@result.column(2)).to eq ["praha", "sum of Age", nil, nil, 25]
    end
  end

  describe '#map' do
    it 'should iterate over rows' do
      expect(@result.each.map {|row| [1]}).to eq [[1], [1], [1], [1], [1]]
    end
  end

  describe '#transpose' do
    it 'should transpose' do
      expect(@result.transpose.to_a).to eq @result.to_a.transpose
      expect(@result.transpose.to_a).to eq [[nil, nil, "jirka", "petr", "tomas"],
                                            ["kolin", "sum of Age", 25, nil, nil],
                                            ["praha", "sum of Age", nil, nil, 25],
                                            ["varsava", "sum of Age", nil, 15, nil]]
    end
  end

  describe '#diff' do
    it 'should support diffing' do
      data = JSON.parse(File.read('./spec/data/reports/left_attr_report.json'))
      a = GoodData::ReportDataResult.from_xtab(data)
      c = GoodData::ReportDataResult.from_xtab(data)
      data = JSON.parse(File.read('./spec/data/reports/top_attr_report.json'))
      b = GoodData::ReportDataResult.from_xtab(data)
      expect {a - b}.to raise_exception
      expect(a - c).to be_empty
    end
  end

  describe 'one line reports' do
    it 'should work with one line metric. No attribtues.' do
      data = JSON.parse(File.read('./spec/data/reports/metric_only_one_line.json'))
      a = GoodData::ReportDataResult.from_xtab(data)
      expect(a.to_a).to eq [[nil, "sum of Age"],
                            ["sum of Age", 65]]

      expect(a.data.to_a).to eq [[65]]
      expect(a.left_headers).to eq [["sum of Age"]]
      expect(a.top_headers).to eq [["sum of Age"]]

      expect(a.without_top_headers.to_a).to eq [["sum of Age", 65]]
      expect(a.without_left_headers.to_a).to eq [["sum of Age"], [65]]
    end
  end
end

